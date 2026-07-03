"""Error types for the Prompt Generator Engine."""


class PromptGeneratorError(Exception):
    """Base class for all Prompt Generator errors."""


class BlankRequirementError(PromptGeneratorError):
    """Raised when the requirement description is empty or blank."""
