from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
import asyncio
import time

app = FastAPI()

class ChatRequest(BaseModel):
    text: str

async def fake_streamer():
    response_text = "This is a response from the local Python backend! I am streaming this text to you."
    for char in response_text:
        yield char
        await asyncio.sleep(0.05)

@app.post("/chat")
async def chat(request: ChatRequest):
    return StreamingResponse(fake_streamer(), media_type="text/plain")
