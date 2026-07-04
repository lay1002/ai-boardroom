"""Template Renderer.

Turns a Template Definition + user input into a `TemplateRuntimePlan`. This
is a planning step only: no perspective/workflow/provider resolution or
execution happens here. See `template_engine_implementation_spec.md`
section 10.
"""

from __future__ import annotations

from typing import Any

from backend.app.engines.template.errors import RenderInputError, TemplateDisabledError
from backend.app.engines.template.loader import TemplateLoader
from backend.app.engines.template.schemas import (
    RuntimePlanInput,
    RuntimePlanOutputSchema,
    RuntimePlanPerspective,
    RuntimePlanTemplateInfo,
    RuntimePlanWorkflow,
    TemplateRuntimePlan,
)


def _validate_user_input(user_input: dict[str, Any]) -> tuple[str, str | None]:
    if "question" not in user_input or user_input["question"] is None:
        raise RenderInputError("Missing required field: question")

    question = user_input["question"]
    if not isinstance(question, str):
        raise RenderInputError("Field 'question' must be a string")
    if not question.strip():
        raise RenderInputError("Field 'question' must not be blank")

    context = user_input.get("context")
    if context is not None and not isinstance(context, str):
        raise RenderInputError("Field 'context' must be a string")

    return question, context


class TemplateRenderer:
    def __init__(self, loader: TemplateLoader):
        self.loader = loader

    def render(self, template_id: str, user_input: dict[str, Any]) -> TemplateRuntimePlan:
        definition = self.loader.load(template_id)

        if definition.status == "disabled":
            raise TemplateDisabledError(
                f"Template '{template_id}' is disabled and cannot be rendered"
            )

        question, context = _validate_user_input(user_input)

        sorted_perspectives = sorted(
            definition.perspectives,
            key=lambda p: (p.order is None, p.order if p.order is not None else 0),
        )

        return TemplateRuntimePlan(
            template=RuntimePlanTemplateInfo(
                template_id=definition.template_id,
                name=definition.name,
                version=definition.version,
                status=definition.status,
            ),
            input=RuntimePlanInput(question=question, context=context),
            workflow=RuntimePlanWorkflow(
                workflow_id=definition.workflow.workflow_id,
                mode=definition.workflow.mode,
            ),
            perspectives=[
                RuntimePlanPerspective(
                    perspective_id=p.perspective_id,
                    required=p.required,
                    order=p.order,
                )
                for p in sorted_perspectives
            ],
            output_schema=RuntimePlanOutputSchema(
                schema_id=definition.output_schema.schema_id
            ),
            prompt_policy=definition.prompt_policy,
            provider_policy=definition.provider_policy,
            moderator=definition.moderator,
            consensus=definition.consensus,
            metadata=definition.metadata,
        )
