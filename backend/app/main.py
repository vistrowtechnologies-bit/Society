import warnings

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse

from app.config import settings
from app.database import Base, engine
from app.routers import (
    auth,
    societies,
    members,
    billing,
    documents,
    complaints,
    notices,
    admin,
    ai_secretary,
    receipts,
    visitors,
    vehicles,
    staff,
    amenities,
    sos,
    polls,
)

Base.metadata.create_all(bind=engine)

# Loudly warn if the app is running with the insecure dev secret. In production
# SECRET_KEY must be a long random value (e.g. `python -c "import secrets; print(secrets.token_urlsafe(48))"`).
if "dev-only" in settings.secret_key:
    warnings.warn(
        "SECRET_KEY is the insecure development default — set a strong SECRET_KEY "
        "in .env before deploying to production.",
        stacklevel=1,
    )

app = FastAPI(title="SocietyOS API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(societies.router)
app.include_router(members.router)
app.include_router(billing.router)
app.include_router(documents.router)
app.include_router(complaints.router)
app.include_router(notices.router)
app.include_router(admin.router)
app.include_router(ai_secretary.router)
app.include_router(receipts.router)
app.include_router(visitors.router)
app.include_router(vehicles.router)
app.include_router(staff.router)
app.include_router(amenities.router)
app.include_router(sos.router)
app.include_router(polls.router)


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")


@app.get("/health")
def health():
    return {"status": "ok"}
