from pathlib import Path

import pytest

from backend.app.engines.template.errors import RenderInputError, TemplateDisabledError
from backend.app.engines.template.loader import TemplateLoader
from backend.app.engines.template.renderer import TemplateRenderer

ACTIVE_TEMPLATE = """
template_id: sample
name: Sample Template
version: 1.0.0
status: active
description: A sample template.
input_schema:
  type: decision-request-v1
  required_fields:
    - question
workflow:
  workflow_id: sample-workflow-v1
  mode: parallel-perspectives
perspectives:
  - perspective_id: cfo
    required: true
    order: 30
  - perspective_id: ceo
    required: true
    order: 10
  - perspective_id: cto
    required: true
    order: 20
output_schema:
  schema_id: sample-output-v1
"""

DISABLED_TEMPLATE = """
template_id: disabled-sample
name: Disabled Sample Template
version: 1.0.0
status: disabled
description: A disabled sample template.
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


def make_renderer(base_dir: Path) -> TemplateRenderer:
    return TemplateRenderer(TemplateLoader(base_dir=base_dir))


def test_render_active_template_produces_runtime_plan(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    plan = renderer.render(
        "sample", {"question": "Enter Japan market?", "context": "APAC expansion"}
    )

    assert plan.template.template_id == "sample"
    assert plan.input.question == "Enter Japan market?"
    assert plan.input.context == "APAC expansion"
    assert plan.workflow.workflow_id == "sample-workflow-v1"
    assert plan.output_schema.schema_id == "sample-output-v1"


def test_render_perspectives_are_sorted_by_order(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    plan = renderer.render("sample", {"question": "Valid question"})

    assert [p.perspective_id for p in plan.perspectives] == ["ceo", "cto", "cfo"]


def test_render_disabled_template_raises(tmp_path):
    write_template(tmp_path, "disabled-sample.yaml", DISABLED_TEMPLATE)
    renderer = make_renderer(tmp_path)

    with pytest.raises(TemplateDisabledError, match="disabled-sample"):
        renderer.render("disabled-sample", {"question": "Should we do X?"})


def test_render_missing_question_fails(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    with pytest.raises(RenderInputError):
        renderer.render("sample", {})


def test_render_blank_question_fails(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    with pytest.raises(RenderInputError):
        renderer.render("sample", {"question": "   "})


def test_render_non_string_question_fails(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    with pytest.raises(RenderInputError):
        renderer.render("sample", {"question": 123})


def test_render_non_string_context_fails(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    with pytest.raises(RenderInputError):
        renderer.render("sample", {"question": "Valid question", "context": 123})


def test_render_omits_absent_optional_policy_fields(tmp_path):
    write_template(tmp_path, "sample.yaml", ACTIVE_TEMPLATE)
    renderer = make_renderer(tmp_path)

    plan = renderer.render("sample", {"question": "Valid question"})
    plan_dict = plan.to_dict()

    for optional_field in ("prompt_policy", "provider_policy", "moderator", "consensus", "metadata"):
        assert optional_field not in plan_dict


def test_render_boardroom_from_project_templates_dir(project_templates_dir):
    renderer = make_renderer(project_templates_dir)

    plan = renderer.render("boardroom", {"question": "是否要進入日本市場？"})
    plan_dict = plan.to_dict()

    required_top_level = {"template", "input", "workflow", "perspectives", "output_schema"}
    assert required_top_level.issubset(plan_dict.keys())

    assert plan_dict["prompt_policy"]["prompt_set_id"] == "boardroom-default-prompts-v1"
    assert plan_dict["provider_policy"]["provider_policy_id"] == "default-multi-model-policy-v1"
    assert plan_dict["moderator"]["strategy_id"] == "synthesize-conflicts-v1"
    assert plan_dict["consensus"]["strategy_id"] == "majority-with-risk-override-v1"
    assert plan_dict["metadata"] == {"category": "strategy", "tags": ["boardroom", "decision"]}

    serialized = str(plan_dict)
    for forbidden_term in ("api_key", "credential", "base_url", "prompt_text"):
        assert forbidden_term not in serialized
