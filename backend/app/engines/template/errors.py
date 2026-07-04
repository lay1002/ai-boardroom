"""Error types for the Template Engine.

Each error type maps to one failure mode listed in
`template_engine_implementation_spec.md` so callers can distinguish them
(file not found, invalid YAML, schema validation, etc.).
"""


class TemplateEngineError(Exception):
    """Base class for all Template Engine errors."""


class TemplateNotFoundError(TemplateEngineError):
    """Raised when the template YAML file does not exist."""


class InvalidYAMLError(TemplateEngineError):
    """Raised when the template file cannot be parsed as YAML."""


class TemplateRootNotMappingError(TemplateEngineError):
    """Raised when the parsed YAML root is not a mapping."""


class TemplateValidationError(TemplateEngineError):
    """Raised when a Template Definition fails schema validation.

    Carries the full list of underlying error messages so callers get a
    single, precise report instead of one exception per field.
    """

    def __init__(self, messages: list[str]):
        self.messages = messages
        super().__init__("; ".join(messages))


class TemplateIDMismatchError(TemplateEngineError):
    """Raised when `template_id` does not match the file stem."""


class TemplateDisabledError(TemplateEngineError):
    """Raised when rendering a template whose status is `disabled`."""


class RenderInputError(TemplateEngineError):
    """Raised when `user_input` passed to the renderer is invalid."""
