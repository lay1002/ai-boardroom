"""Template Loader.

I/O boundary of the Template Engine: finds `templates/<template_id>.yaml`,
parses it, and delegates schema validation to `validator.py`. See
`template_engine_implementation_spec.md` section 8.
"""

from __future__ import annotations

from pathlib import Path

import yaml

from backend.app.engines.template.errors import (
    InvalidYAMLError,
    TemplateNotFoundError,
    TemplateValidationError,
)
from backend.app.engines.template.schemas import ID_PATTERN, TemplateDefinition
from backend.app.engines.template.validator import validate_template_definition

DEFAULT_BASE_DIR = Path("templates")


class TemplateLoader:
    def __init__(self, base_dir: Path | str = DEFAULT_BASE_DIR):
        self.base_dir = Path(base_dir)
        self._cache: dict[str, TemplateDefinition] = {}

    def load(self, template_id: str) -> TemplateDefinition:
        """Load and validate a single template by id. Cached per instance."""
        if template_id in self._cache:
            return self._cache[template_id]

        if not ID_PATTERN.match(template_id):
            raise TemplateValidationError(
                [
                    "template_id must be lowercase kebab-case matching "
                    f"'{ID_PATTERN.pattern}', got: {template_id!r}"
                ]
            )

        path = self.base_dir / f"{template_id}.yaml"
        if not path.is_file():
            raise TemplateNotFoundError(f"Template file not found: {path}")

        text = path.read_text(encoding="utf-8")
        try:
            raw = yaml.safe_load(text)
        except yaml.YAMLError as exc:
            raise InvalidYAMLError(f"Invalid YAML in {path}: {exc}") from exc

        definition = validate_template_definition(raw, expected_template_id=template_id)
        self._cache[template_id] = definition
        return definition

    def load_all(self) -> list[TemplateDefinition]:
        """Load every `*.yaml` template in `base_dir`, sorted by template_id."""
        definitions = [self.load(path.stem) for path in self.base_dir.glob("*.yaml")]
        return sorted(definitions, key=lambda d: d.template_id)
