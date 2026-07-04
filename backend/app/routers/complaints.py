from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Complaint, Flat, Tower, User
from app.schemas import ComplaintCreate, ComplaintOut, ComplaintStatusUpdate
from app.security import (
    get_current_user,
    require_admin,
    ensure_society_access,
    ensure_flat_access,
)

router = APIRouter(prefix="/complaints", tags=["complaints"])


@router.post("", response_model=ComplaintOut)
def raise_complaint(
    payload: ComplaintCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_flat_access(db, current_user, payload.flat_id)
    flat = db.query(Flat).get(payload.flat_id)
    if not flat:
        raise HTTPException(status_code=404, detail="Flat not found")
    tower = db.query(Tower).get(flat.tower_id)

    complaint = Complaint(
        society_id=tower.society_id,
        flat_id=payload.flat_id,
        raised_by=current_user.id,
        category=payload.category,
        title=payload.title,
        description=payload.description,
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)
    return complaint


@router.get("/me", response_model=List[ComplaintOut])
def my_complaints(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Complaint).filter(Complaint.raised_by == current_user.id).order_by(Complaint.created_at.desc()).all()


@router.get("/society/{society_id}", response_model=List[ComplaintOut])
def list_society_complaints(
    society_id: int,
    status_filter: Optional[str] = None,
    limit: int = Query(200, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    query = db.query(Complaint).filter(Complaint.society_id == society_id)
    if status_filter:
        query = query.filter(Complaint.status == status_filter)
    return query.order_by(Complaint.created_at.desc()).offset(offset).limit(limit).all()


@router.patch("/{complaint_id}/status", response_model=ComplaintOut)
def update_complaint_status(
    complaint_id: int,
    payload: ComplaintStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    complaint = db.query(Complaint).get(complaint_id)
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    ensure_society_access(current_user, complaint.society_id)
    complaint.status = payload.status
    db.commit()
    db.refresh(complaint)
    return complaint
