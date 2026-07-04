from pathlib import Path

import pytest

from backend.app.engines.template.errors import (
    InvalidYAMLError,
    TemplateIDMismatchError,
    TemplateNotFoundError,
    TemplateRootNotMappingError,
    TemplateValidationError,
)
from backend.app.engines.template.loader import TemplateLoader

VALID_YAML = """
template_id: sample
name: Sample Template
version: 1.0.0
status: active
description: A sample template for tests.
input_schema:
  type: decision-request-v1
  required_fields:
    - question
workflow:
  workflow_id: sample-workflow-v1
perspectives:
  - perspective_id: ceo
    required: true
    order: 10
output_schema:
  schema_id: sample-output-v1
"""


def write_template(dir_path: Path, filename: str, content: str) -> None:
    (dir_path / filename).write_text(content, encoding="utf-8")


def test_load_boardroom_from_project_templates_dir(project_templates_dir):
    loader = TemplateLoader(base_dir=project_templates_dir)
    definition = loader.load("boardroom")
    assert definition.template_id == "boardroom"
    assert definition.status == "active"
    assert len(definition.perspectives) == 5


def test_load_missing_file_raises_clear_error(tmp_path):
    loader = TemplateLoader(base_dir=tmp_path)
    with pytest.raises(TemplateNotFoundError, match="does-not-exist"):
        loader.load("does-not-exist")


def test_load_invalid_yaml_raises_clear_error(tmp_path):
    write_template(tmp_path, "broken.yaml", "template_id: [unclosed")
    loader = TemplateLoader(base_dir=tmp_path)
    with pytest.raises(InvalidYAMLError):
        loader.load("broken")


def test_load_yaml_root_not_mapping_raises_clear_error(tmp_path):
    write_template(tmp_path, "list-root.yaml", "- a\n- b\n")
    loader = TemplateLoader(base_dir=tmp_path)
    with pytest.raises(TemplateRootNotMappingError):
        loader.load("list-root")


def test_load_template_id_mismatch_raises_clear_error(tmp_path):
    # File is named other-name.yaml but its template_id is "sample".
    write_template(tmp_path, "other-name.yaml", VALID_YAML)
    loader = TemplateLoader(base_dir=tmp_path)
    with pytest.raises(TemplateIDMismatchError):
        loader.load("other-name")


def test_load_all_returns_templates_sorted_by_template_id(tmp_path):
    write_template(tmp_path, "zeta.yaml", VALID_YAML.replace("sample", "zeta"))
    write_template(tmp_path, "alpha.yaml", VALID_YAML.replace("sample", "alpha"))
    loader = TemplateLoader(base_dir=tmp_path)
    definitions = loader.load_all()
    assert [d.template_id for d in definitions] == ["alpha", "zeta"]


def test_load_caches_result(tmp_path):
    write_template(tmp_path, "sample.yaml", VALID_YAML)
    loader = TemplateLoader(base_dir=tmp_path)
    first = loader.load("sample")
    second = loader.load("sample")
    assert first is second


def test_load_invalid_template_id_rejected_before_file_lookup(tmp_path):
    loader = TemplateLoader(base_dir=tmp_path)
    with pytest.raises(TemplateValidationError):
        loader.load("Not_Kebab_Case")


def test_load_path_traversal_template_id_rejected_before_file_lookup(tmp_path):
    # A secret file outside the template base_dir that traversal must not reach.
    secret_dir = tmp_path.parent
    write_template(secret_dir, "secret.yaml", VALID_YAML)
    loader = TemplateLoader(base_dir=tmp_path)

    with pytest.raises(TemplateValidationError):
        loader.load("../secret")
