import uuid

from fastapi import FastAPI, HTTPException
from google.adk.runners import InMemoryRunner
from google.genai import types as genai_types
from pydantic import BaseModel

from agent import root_agent

app = FastAPI()
runner = InMemoryRunner(agent=root_agent, app_name="chat_agent_service")

APP_NAME = "chat_agent_service"
USER_ID = "api-user"


class Message(BaseModel):
    role: str
    text: str


class ChatRequest(BaseModel):
    messages: list[Message]


class ChatResponse(BaseModel):
    message: Message


def _build_context(messages: list[Message]) -> str:
    """Format prior messages as conversation context."""
    lines: list[str] = []
    for msg in messages:
        label = "User" if msg.role == "user" else "Assistant"
        lines.append(f"{label}: {msg.text}")
    return "\n".join(lines)


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    if not request.messages:
        raise HTTPException(status_code=400, detail="messages must not be empty")

    session_id = str(uuid.uuid4())
    await runner.session_service.create_session(
        app_name=APP_NAME,
        user_id=USER_ID,
        session_id=session_id,
    )

    # Build the user prompt with conversation history as context
    last_msg = request.messages[-1]
    history = request.messages[:-1]

    if history:
        context = _build_context(history)
        prompt = (
            f"Here is the conversation so far:\n{context}\n\n"
            f"User: {last_msg.text}"
        )
    else:
        prompt = last_msg.text

    new_message = genai_types.Content(
        role="user",
        parts=[genai_types.Part(text=prompt)],
    )

    # Run the agent and collect only the final response
    response_text = ""
    async for event in runner.run_async(
        user_id=USER_ID,
        session_id=session_id,
        new_message=new_message,
    ):
        if event.is_final_response() and event.content and event.content.parts:
            for part in event.content.parts:
                if part.text:
                    response_text += part.text

    return ChatResponse(message=Message(role="model", text=response_text))


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
