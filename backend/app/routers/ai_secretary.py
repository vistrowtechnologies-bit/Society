from fastapi import APIRouter, Depends, HTTPException
from openai import OpenAI
from pydantic import BaseModel

from app.config import settings
from app.models import User
from app.security import require_admin

router = APIRouter(prefix="/ai", tags=["ai"])

SYSTEM_PROMPT = (
    "You are the AI Secretary for an Indian housing society management platform called SocietyOS. "
    "Draft formal, legally-toned society documents (AGM notices, circulars, maintenance announcements) "
    "in plain text. Follow the structure: a title line, then the body. Keep it concise and professional. "
    "Do not use markdown formatting."
)


class DraftRequest(BaseModel):
    prompt: str
    society_name: str = "the society"


class DraftResponse(BaseModel):
    title: str
    body: str


@router.post("/generate-notice", response_model=DraftResponse)
def generate_notice(payload: DraftRequest, current_user: User = Depends(require_admin)):
    if not settings.openai_api_key:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY not configured on the server")

    client = OpenAI(api_key=settings.openai_api_key)
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": f"Society: {payload.society_name}\nRequest: {payload.prompt}\n\n"
                    "Respond with the title on the first line and the full notice body after it.",
                },
            ],
            temperature=0.4,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI generation failed: {e}")

    text = completion.choices[0].message.content.strip()
    lines = text.split("\n", 1)
    title = lines[0].strip().lstrip("#").strip()
    body = lines[1].strip() if len(lines) > 1 else ""
    return DraftResponse(title=title, body=body)
