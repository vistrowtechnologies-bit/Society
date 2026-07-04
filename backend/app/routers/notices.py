from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Notice, Society, User
from app.schemas import NoticeCreate, NoticeOut, NoticeUpdate
from app.security import get_current_user, require_admin, ensure_society_access

router = APIRouter(prefix="/notices", tags=["notices"])


@router.post("", response_model=NoticeOut)
def create_notice(
    payload: NoticeCreate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    ensure_society_access(current_user, payload.society_id)
    if not db.query(Society).get(payload.society_id):
        raise HTTPException(status_code=404, detail="Society not found")
    notice = Notice(
        society_id=payload.society_id,
        posted_by=current_user.id,
        category=payload.category,
        title=payload.title,
        body=payload.body,
    )
    db.add(notice)
    db.commit()
    db.refresh(notice)
    return notice


@router.get("/society/{society_id}", response_model=List[NoticeOut])
def list_notices(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_society_access(current_user, society_id)
    return (
        db.query(Notice)
        .filter(Notice.society_id == society_id)
        .order_by(Notice.created_at.desc())
        .all()
    )


@router.get("/{notice_id}", response_model=NoticeOut)
def get_notice(
    notice_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notice = db.query(Notice).get(notice_id)
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    ensure_society_access(current_user, notice.society_id)
    return notice


@router.patch("/{notice_id}", response_model=NoticeOut)
def edit_notice(
    notice_id: int,
    payload: NoticeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    notice = db.query(Notice).get(notice_id)
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    ensure_society_access(current_user, notice.society_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(notice, field, value)
    db.commit()
    db.refresh(notice)
    return notice


@router.delete("/{notice_id}", status_code=204)
def delete_notice(
    notice_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    notice = db.query(Notice).get(notice_id)
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    ensure_society_access(current_user, notice.society_id)
    db.delete(notice)
    db.commit()
