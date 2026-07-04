from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import SOSAlert, SOSStatus, User
from app.schemas import SOSCreate, SOSOut
from app.security import (
    get_current_user,
    require_gate_staff,
    ensure_flat_access,
    ensure_society_access,
    society_id_for_flat,
)

router = APIRouter(prefix="/sos", tags=["sos"])


@router.post("", response_model=SOSOut)
def raise_sos(
    payload: SOSCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, payload.flat_id)
    society_id = society_id_for_flat(db, payload.flat_id)

    alert = SOSAlert(
        society_id=society_id,
        flat_id=payload.flat_id,
        raised_by=current_user.id,
        message=payload.message,
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return alert


@router.get("/society/{society_id}", response_model=List[SOSOut])
def list_society_alerts(
    society_id: int,
    active_only: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    ensure_society_access(current_user, society_id)
    query = db.query(SOSAlert).filter(SOSAlert.society_id == society_id)
    if active_only:
        query = query.filter(SOSAlert.status == SOSStatus.active)
    return query.order_by(SOSAlert.created_at.desc()).all()


@router.get("/mine", response_model=List[SOSOut])
def my_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(SOSAlert)
        .filter(SOSAlert.raised_by == current_user.id)
        .order_by(SOSAlert.created_at.desc())
        .limit(50)
        .all()
    )


@router.patch("/{alert_id}/resolve", response_model=SOSOut)
def resolve_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    alert = db.query(SOSAlert).get(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    ensure_society_access(current_user, alert.society_id)

    alert.status = SOSStatus.resolved
    alert.resolved_at = datetime.utcnow()
    alert.resolved_by = current_user.id
    db.commit()
    db.refresh(alert)
    return alert
