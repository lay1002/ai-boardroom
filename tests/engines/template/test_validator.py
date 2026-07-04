from copy import deepcopy
from typing import Any

import pytest

from backend.app.engines.template.errors import (
    TemplateIDMismatchError,
    TemplateRootNotMappingError,
    TemplateValidationError,
)
from backend.app.engines.template.validator import validate_template_definition


def valid_template_dict(**overrides: Any) -> dict:
    base = {
        "template_id": "sample",
        "name": "Sample Template",
        "version": "1.0.0",
        "status": "active",
        "description": "A sample template.",
        "input_schema": {
            "type": "decision-request-v1",
            "required_fields": ["question"],
        },
        "workflow": {"workflow_id": "sample-workflow-v1"},
        "perspectives": [
            {"perspective_id": "ceo", "required": True, "order": 10},
        ],
        "output_schema": {"schema_id": "sample-output-v1"},
    }
    base.update(overrides)
    return deepcopy(base)


def test_valid_template_passes():
    definition = validate_template_definition(valid_template_dict(), expected_template_id="sample")
    assert definition.template_id == "sample"


def test_root_not_mapping_fails():
    with pytest.raises(TemplateRootNotMappingError):
        validate_template_definition(["not", "a", "mapping"], expected_template_id="sample")


def test_missing_required_field_fails():
    data = valid_template_dict()
    del data["output_schema"]
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_unknown_top_level_field_fails():
    data = valid_template_dict(unexpected_field="oops")
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_template_id_mismatch_fails():
    data = valid_template_dict()
    with pytest.raises(TemplateIDMismatchError):
        validate_template_definition(data, expected_template_id="other")


def test_invalid_id_naming_fails():
    data = valid_template_dict(template_id="Sample_ID")
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="Sample_ID")


def test_invalid_status_fails():
    data = valid_template_dict(status="archived")
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_duplicate_perspective_fails():
    data = valid_template_dict(
        perspectives=[
            {"perspective_id": "ceo", "required": True, "order": 10},
            {"perspective_id": "ceo", "required": True, "order": 20},
        ]
    )
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_empty_perspectives_fails():
    data = valid_template_dict(perspectives=[])
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_invalid_order_fails():
    data = valid_template_dict(
        perspectives=[{"perspective_id": "ceo", "required": True, "order": 0}]
    )
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")


def test_missing_question_in_required_fields_fails():
    data = valid_template_dict(
        input_schema={"type": "decision-request-v1", "required_fields": ["context"]}
    )
    with pytest.raises(TemplateValidationError):
        validate_template_definition(data, expected_template_id="sample")
