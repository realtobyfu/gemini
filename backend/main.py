from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
import asyncio
import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Configure Gemini
API_KEY = os.environ.get("GEMINI_API_KEY")
if API_KEY:
    genai.configure(api_key=API_KEY)
    model = genai.GenerativeModel('gemini-2.5-flash-lite')
else:
    model = None
    print("WARNING: GEMINI_API_KEY not set")

class ChatRequest(BaseModel):
    text: str
    max_tokens: int = 1000  # Default limit

async def gemini_streamer(text: str, max_tokens: int):
    if not model:
        yield "Error: GEMINI_API_KEY not set on backend."
        return

    try:
        response = await model.generate_content_async(
            text, 
            stream=True,
            generation_config=genai.types.GenerationConfig(
                max_output_tokens=max_tokens
            )
        )
        async for chunk in response:
            if chunk.text:
                yield chunk.text
    except Exception as e:
        yield f"Error generating response: {str(e)}"

@app.post("/chat")
async def chat(request: ChatRequest):
    return StreamingResponse(gemini_streamer(request.text, request.max_tokens), media_type="text/plain")
