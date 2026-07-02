from fastapi import FastAPI
from pydantic import BaseModel

from orchestrator import run_boardroom


app = FastAPI(
    title="AI Boardroom",
    version="1.0.0"
)


class QuestionRequest(BaseModel):
    question: str


@app.get("/")
def home():
    return {
        "name": "AI Boardroom",
        "version": "1.0.0",
        "status": "running"
    }


@app.post("/api/boardroom")
def boardroom(request: QuestionRequest):
    return run_boardroom(request.question)