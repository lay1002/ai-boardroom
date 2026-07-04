"""Pydantic models for Template Definition and Template Runtime Plan.

Field rules follow `template_engine_implementation_spec.md` sections 2, 3, 6, 7.
"""

from __future__ import annotations

import re
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, field_validator

ID_PATTERN = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")

TemplateStatus = Literal["active", "disabled"]


def _validate_id(value: str, field_name: str) -> str:
    if not ID_PATTERN.match(value):
        raise ValueError(
            f"{field_name} must be lowercase kebab-case matching "
            f"'{ID_PATTERN.pattern}', got: {value!r}"
        )
    return value


# ---------------------------------------------------------------------------
# Template Definition (parsed from templates/<template_id>.yaml)
# ---------------------------------------------------------------------------


class InputSchemaRef(BaseModel):
    type: str
    required_fields: list[str]

    @field_validator("type")
    @classmethod
    def _check_type(cls, v: str) -> str:
        return _validate_id(v, "input_schema.type")

    @field_validator("required_fields")
    @classmethod
    def _check_required_fields(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("input_schema.required_fields must not be empty")
        if "question" not in v:
            raise ValueError("input_schema.required_fields must include 'question'")
        return v


class WorkflowRef(BaseModel):
    workflow_id: str
    mode: Optional[str] = None

    @field_validator("workflow_id")
    @classmethod
    def _check_workflow_id(cls, v: str) -> str:
        return _validate_id(v, "workflow.workflow_id")

    @field_validator("mode")
    @classmethod
    def _check_mode(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        return _validate_id(v, "workflow.mode")


class PerspectiveRef(BaseModel):
    perspective_id: str
    required: bool
    order: Optional[int] = None

    @field_validator("perspective_id")
    @classmethod
    def _check_perspective_id(cls, v: str) -> str:
        return _validate_id(v, "perspectives[].perspective_id")

    @field_validator("order")
    @classmethod
    def _check_order(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v <= 0:
            raise ValueError("perspectives[].order must be a positive integer")
        return v


class PromptPolicyRef(BaseModel):
    prompt_set_id: str

    @field_validator("prompt_set_id")
    @classmethod
    def _check(cls, v: str) -> str:
        return _validate_id(v, "prompt_policy.prompt_set_id")


class ProviderPolicyRef(BaseModel):
    provider_policy_id: str

    @field_validator("provider_policy_id")
    @classmethod
    def _check(cls, v: str) -> str:
        return _validate_id(v, "provider_policy.provider_policy_id")


class ModeratorRef(BaseModel):
    strategy_id: str

    @field_validator("strategy_id")
    @classmethod
    def _check(cls, v: str) -> str:
        return _validate_id(v, "moderator.strategy_id")


class ConsensusRef(BaseModel):
    strategy_id: str

    @field_validator("strategy_id")
    @classmethod
    def _check(cls, v: str) -> str:
        return _validate_id(v, "consensus.strategy_id")


class OutputSchemaRef(BaseModel):
    schema_id: str

    @field_validator("schema_id")
    @classmethod
    def _check(cls, v: str) -> str:
        return _validate_id(v, "output_schema.schema_id")


class TemplateDefinition(BaseModel):
    model_config = ConfigDict(extra="forbid")

    template_id: str
    name: str
    version: str
    status: TemplateStatus
    description: str
    input_schema: InputSchemaRef
    workflow: WorkflowRef
    perspectives: list[PerspectiveRef]
    output_schema: OutputSchemaRef
    prompt_policy: Optional[PromptPolicyRef] = None
    provider_policy: Optional[ProviderPolicyRef] = None
    moderator: Optional[ModeratorRef] = None
    consensus: Optional[ConsensusRef] = None
    metadata: Optional[dict] = None

    @field_validator("template_id")
    @classmethod
    def _check_template_id(cls, v: str) -> str:
        return _validate_id(v, "template_id")

    @field_validator("name")
    @classmethod
    def _check_name(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("name must not be blank")
        return v

    @field_validator("version")
    @classmethod
    def _check_version(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("version must not be blank")
        return v

    @field_validator("description")
    @classmethod
    def _check_description(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("description must not be blank")
        return v

    @field_validator("perspectives")
    @classmethod
    def _check_perspectives(cls, v: list[PerspectiveRef]) -> list[PerspectiveRef]:
        if not v:
            raise ValueError("perspectives must not be empty")
        seen: set[str] = set()
        duplicates: set[str] = set()
        for p in v:
            if p.perspective_id in seen:
                duplicates.add(p.perspective_id)
            seen.add(p.perspective_id)
        if duplicates:
            raise ValueError(
                f"perspectives[].perspective_id must not contain duplicates: "
                f"{sorted(duplicates)}"
            )
        return v


# ---------------------------------------------------------------------------
# Template Runtime Plan (render output)
# ---------------------------------------------------------------------------


class RuntimePlanTemplateInfo(BaseModel):
    template_id: str
    name: str
    version: str
    status: TemplateStatus


class RuntimePlanInput(BaseModel):
    question: str
    context: Optional[str] = None


class RuntimePlanWorkflow(BaseModel):
    workflow_id: str
    mode: Optional[str] = None


class RuntimePlanPerspective(BaseModel):
    perspective_id: str
    required: bool
    order: Optional[int] = None


class RuntimePlanOutputSchema(BaseModel):
    schema_id: str


class TemplateRuntimePlan(BaseModel):
    template: RuntimePlanTemplateInfo
    input: RuntimePlanInput
    workflow: RuntimePlanWorkflow
    perspectives: list[RuntimePlanPerspective]
    output_schema: RuntimePlanOutputSchema
    prompt_policy: Optional[PromptPolicyRef] = None
    provider_policy: Optional[ProviderPolicyRef] = None
    moderator: Optional[ModeratorRef] = None
    consensus: Optional[ConsensusRef] = None
    metadata: Optional[dict] = None

    def to_dict(self) -> dict:
        """Serialize while omitting absent optional reference fields."""
        return self.model_dump(exclude_none=True)
