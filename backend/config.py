import os
from dotenv import load_dotenv

load_dotenv()

AGNES_API_KEY = os.getenv("AGNES_API_KEY")
AGNES_BASE_URL = os.getenv("AGNES_BASE_URL")
AGNES_MODEL = os.getenv("AGNES_MODEL", "agnes-2.0-flash")

if not AGNES_API_KEY:
    raise RuntimeError("AGNES_API_KEY is missing in .env")

if not AGNES_BASE_URL:
    raise RuntimeError("AGNES_BASE_URL is missing in .env")
