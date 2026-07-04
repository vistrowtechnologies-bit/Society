from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Staff, StaffAttendance, User
from app.schemas import StaffCreate, StaffOut, StaffVerifyUpdate, StaffAttendanceOut
from app.security import (
    get_current_user,
    require_admin,
    require_gate_staff,
    ensure_society_access,
    ensure_flat_access,
)

router = APIRouter(prefix="/staff", tags=["staff"])


@router.post("", response_model=StaffOut)
def add_staff(
    payload: StaffCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.flat_id is not None:
        ensure_flat_access(db, current_user, payload.flat_id)
        society_id = current_user.society_id
    else:
        if current_user.society_id is None:
            raise HTTPException(status_code=400, detail="No society associated with this account")
        society_id = current_user.society_id

    staff = Staff(society_id=society_id, **payload.model_dump())
    db.add(staff)
    db.commit()
    db.refresh(staff)
    return staff


@router.get("/flat/{flat_id}", response_model=List[StaffOut])
def list_flat_staff(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, flat_id)
    return db.query(Staff).filter(Staff.flat_id == flat_id).all()


@router.get("/society/{society_id}", response_model=List[StaffOut])
def list_society_staff(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    ensure_society_access(current_user, society_id)
    return db.query(Staff).filter(Staff.society_id == society_id).all()


@router.patch("/{staff_id}/verify", response_model=StaffOut)
def verify_staff(
    staff_id: int,
    payload: StaffVerifyUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    member = db.query(Staff).get(staff_id)
    if not member:
        raise HTTPException(status_code=404, detail="Staff not found")
    ensure_society_access(current_user, member.society_id)
    member.is_verified = payload.is_verified
    db.commit()
    db.refresh(member)
    return member


@router.post("/{staff_id}/check-in", response_model=StaffAttendanceOut)
def staff_check_in(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    member = db.query(Staff).get(staff_id)
    if not member:
        raise HTTPException(status_code=404, detail="Staff not found")
    ensure_society_access(current_user, member.society_id)

    open_entry = (
        db.query(StaffAttendance)
        .filter(StaffAttendance.staff_id == staff_id, StaffAttendance.checked_out_at.is_(None))
        .first()
    )
    if open_entry:
        raise HTTPException(status_code=400, detail="Staff member is already checked in")

    entry = StaffAttendance(staff_id=staff_id)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.post("/{staff_id}/check-out", response_model=StaffAttendanceOut)
def staff_check_out(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    from datetime import datetime

    member = db.query(Staff).get(staff_id)
    if not member:
        raise HTTPException(status_code=404, detail="Staff not found")
    ensure_society_access(current_user, member.society_id)

    entry = (
        db.query(StaffAttendance)
        .filter(StaffAttendance.staff_id == staff_id, StaffAttendance.checked_out_at.is_(None))
        .first()
    )
    if not entry:
        raise HTTPException(status_code=400, detail="Staff member is not checked in")

    entry.checked_out_at = datetime.utcnow()
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/{staff_id}/attendance", response_model=List[StaffAttendanceOut])
def staff_attendance_history(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_gate_staff),
):
    member = db.query(Staff).get(staff_id)
    if not member:
        raise HTTPException(status_code=404, detail="Staff not found")
    ensure_society_access(current_user, member.society_id)
    return (
        db.query(StaffAttendance)
        .filter(StaffAttendance.staff_id == staff_id)
        .order_by(StaffAttendance.checked_in_at.desc())
        .limit(100)
        .all()
    )
