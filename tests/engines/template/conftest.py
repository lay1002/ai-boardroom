from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[3]


@pytest.fixture
def project_templates_dir() -> Path:
    """Points at the real `templates/` directory (contains boardroom.yaml)."""
    return PROJECT_ROOT / "templates"
