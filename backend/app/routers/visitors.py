from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Visitor, VisitorStatus, User
from app.schemas import VisitorCreate, VisitorOut, VisitorStatusUpdate
from app.security import (
    get_current_user,
    require_gate_staff,
    ensure_flat_access,
    ensure_gate_flat_access,
    society_id_for_flat,
)

router = APIRouter(prefix="/visitors", tags=["visitors"])


@router.post("", response_model=VisitorOut)
def pre_approve_visitor(
    payload: VisitorCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """A resident pre-approves an expected visitor, or gate staff logs a walk-in."""
    ensure_gate_flat_access(db, current_user, payload.flat_id)
    society_id = society_id_for_flat(db, payload.flat_id)

    visitor = Visitor(
        society_id=society_id,
        flat_id=payload.flat_id,
        name=payload.name,
        phone=payload.phone,
        purpose=payload.purpose,
        status=VisitorStatus.approved,
        pre_approved_by=current_user.id,
    )
    db.add(visitor)
    db.commit()
    db.refresh(visitor)
    return visitor


@router.get("/flat/{flat_id}", response_model=List[VisitorOut])
def list_flat_visitors(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_gate_flat_access(db, current_user, flat_id)
    return (
        db.query(Visitor)
        .filter(Visitor.flat_id == flat_id)
        .order_by(Visitor.created_at.desc())
        .all()
    )


@router.get("/society/{society_id}", response_model=List[VisitorOut])
def list_society_visitors(
    society_id: int,
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    from app.security import ensure_society_access

    ensure_society_access(current_user, society_id)
    query = db.query(Visitor).filter(Visitor.society_id == society_id)
    if status_filter:
        query = query.filter(Visitor.status == status_filter)
    return query.order_by(Visitor.created_at.desc()).limit(200).all()


@router.patch("/{visitor_id}/status", response_model=VisitorOut)
def update_visitor_status(
    visitor_id: int,
    payload: VisitorStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    visitor = db.query(Visitor).get(visitor_id)
    if not visitor:
        raise HTTPException(status_code=404, detail="Visitor not found")
    ensure_gate_flat_access(db, current_user, visitor.flat_id)

    visitor.status = payload.status
    if payload.status == VisitorStatus.checked_in:
        visitor.checked_in_at = datetime.utcnow()
        visitor.checked_in_by = current_user.id
    elif payload.status == VisitorStatus.checked_out:
        visitor.checked_out_at = datetime.utcnow()

    db.commit()
    db.refresh(visitor)
    return visitor
