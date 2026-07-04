from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    MaintenanceBill,
    Payment,
    Flat,
    Tower,
    Membership,
    User,
    Complaint,
    ComplaintStatus,
    BillStatus,
)
from app.security import require_admin, ensure_society_access

router = APIRouter(prefix="/admin", tags=["admin"])


class DashboardSummary(BaseModel):
    society_id: int
    collection_percent: float
    total_dues: float
    defaulters_count: int
    open_complaints_count: int
    urgent_complaints_count: int


class DirectoryEntry(BaseModel):
    flat_id: int
    flat_number: str
    tower_name: str
    resident_name: Optional[str] = None
    relation: Optional[str] = None
    outstanding_dues: float = 0


@router.get("/dashboard/{society_id}", response_model=DashboardSummary)
def dashboard_summary(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    bills = (
        db.query(MaintenanceBill)
        .join(Flat, MaintenanceBill.flat_id == Flat.id)
        .join(Tower, Flat.tower_id == Tower.id)
        .filter(Tower.society_id == society_id)
        .all()
    )
    total_billed = sum(b.amount + b.late_fee for b in bills)
    total_collected = sum(sum(p.amount for p in b.payments) for b in bills)
    collection_percent = round((total_collected / total_billed) * 100, 1) if total_billed else 0.0
    total_dues = round(total_billed - total_collected, 2)
    defaulters_count = len(
        [
            b
            for b in bills
            if b.status in (BillStatus.pending, BillStatus.partial, BillStatus.overdue) and b.due_date < date.today()
        ]
    )

    complaints = db.query(Complaint).filter(Complaint.society_id == society_id).all()
    open_complaints = [c for c in complaints if c.status != ComplaintStatus.resolved]

    return DashboardSummary(
        society_id=society_id,
        collection_percent=collection_percent,
        total_dues=total_dues,
        defaulters_count=defaulters_count,
        open_complaints_count=len(open_complaints),
        urgent_complaints_count=len([c for c in open_complaints if c.status == ComplaintStatus.open]),
    )


@router.get("/directory/{society_id}", response_model=List[DirectoryEntry])
def directory(
    society_id: int,
    limit: int = Query(200, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    flats = (
        db.query(Flat)
        .join(Tower, Flat.tower_id == Tower.id)
        .filter(Tower.society_id == society_id)
        .order_by(Flat.id)
        .offset(offset)
        .limit(limit)
        .all()
    )
    results = []
    for flat in flats:
        tower = db.query(Tower).get(flat.tower_id)
        membership = db.query(Membership).filter(Membership.flat_id == flat.id, Membership.is_primary == True).first()  # noqa: E712
        resident = db.query(User).get(membership.user_id) if membership else None

        bills = db.query(MaintenanceBill).filter(MaintenanceBill.flat_id == flat.id).all()
        outstanding = sum(
            (b.amount + b.late_fee - sum(p.amount for p in b.payments))
            for b in bills
            if b.status != BillStatus.paid
        )

        results.append(
            DirectoryEntry(
                flat_id=flat.id,
                flat_number=flat.number,
                tower_name=tower.name,
                resident_name=resident.full_name if resident else None,
                relation=membership.relation.value if membership else None,
                outstanding_dues=round(outstanding, 2),
            )
        )
    return results
