"""Template Validator.

Validates a raw parsed-YAML mapping against the Template Definition schema
and returns a `TemplateDefinition`. See
`template_engine_implementation_spec.md` section 9 for the full rule list.
"""

from __future__ import annotations

from typing import Any

from pydantic import ValidationError

from backend.app.engines.template.errors import (
    TemplateIDMismatchError,
    TemplateRootNotMappingError,
    TemplateValidationError,
)
from backend.app.engines.template.schemas import TemplateDefinition


def _format_pydantic_errors(exc: ValidationError) -> list[str]:
    messages = []
    for error in exc.errors():
        loc = ".".join(str(part) for part in error["loc"])
        msg = error["msg"]
        messages.append(f"{loc}: {msg}" if loc else msg)
    return messages


def validate_template_definition(
    raw: Any, expected_template_id: str
) -> TemplateDefinition:
    """Validate a raw parsed-YAML mapping and return a TemplateDefinition.

    Raises:
        TemplateRootNotMappingError: `raw` is not a mapping.
        TemplateValidationError: schema validation failed (missing/unknown
            fields, invalid IDs, invalid status, duplicate perspectives, ...).
        TemplateIDMismatchError: `template_id` does not match
            `expected_template_id` (the file stem).
    """
    if not isinstance(raw, dict):
        raise TemplateRootNotMappingError(
            "Template YAML root must be a mapping, got "
            f"{type(raw).__name__}"
        )

    try:
        definition = TemplateDefinition.model_validate(raw)
    except ValidationError as exc:
        raise TemplateValidationError(_format_pydantic_errors(exc)) from exc

    if definition.template_id != expected_template_id:
        raise TemplateIDMismatchError(
            f"template_id '{definition.template_id}' does not match "
            f"file name 'templates/{expected_template_id}.yaml'"
        )

    return definition
