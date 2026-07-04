import os
import shutil
from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Document, Society, User
from app.schemas import DocumentOut
from app.security import get_current_user, require_admin, ensure_society_access

router = APIRouter(prefix="/documents", tags=["documents"])


@router.post("", response_model=DocumentOut)
def upload_document(
    society_id: int = Form(...),
    category: str = Form(...),
    title: str = Form(...),
    expiry_date: Optional[date] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    if not db.query(Society).get(society_id):
        raise HTTPException(status_code=404, detail="Society not found")

    # Strip any directory components from the client-supplied filename so a
    # crafted name like "../../.env" cannot escape the society's upload folder.
    safe_name = os.path.basename(file.filename or "upload")
    if not safe_name or safe_name in (".", ".."):
        safe_name = "upload"

    society_dir = os.path.abspath(os.path.join(settings.upload_dir, str(society_id)))
    os.makedirs(society_dir, exist_ok=True)
    dest_path = os.path.join(society_dir, safe_name)

    # Defense in depth: confirm the resolved path stays inside the society dir.
    if os.path.commonpath([society_dir, os.path.abspath(dest_path)]) != society_dir:
        raise HTTPException(status_code=400, detail="Invalid file name")

    with open(dest_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    document = Document(
        society_id=society_id,
        category=category,
        title=title,
        file_path=dest_path,
        expiry_date=expiry_date,
    )
    db.add(document)
    db.commit()
    db.refresh(document)
    return document


@router.get("/society/{society_id}", response_model=List[DocumentOut])
def list_documents(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_society_access(current_user, society_id)
    return db.query(Document).filter(Document.society_id == society_id).all()


@router.delete("/{document_id}", status_code=204)
def delete_document(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    document = db.query(Document).get(document_id)
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    ensure_society_access(current_user, document.society_id)
    # Best-effort file removal; the DB row is the source of truth.
    try:
        if os.path.exists(document.file_path):
            os.remove(document.file_path)
    except OSError:
        pass
    db.delete(document)
    db.commit()
