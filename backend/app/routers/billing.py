from datetime import date
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MaintenanceBill, Flat, Tower, Payment, BillStatus, User
from app.schemas import (
    BillCreate,
    BillOut,
    BillGenerateForSociety,
    PaymentCreate,
    PaymentOut,
)
from app.security import (
    get_current_user,
    require_admin,
    ensure_society_access,
    ensure_flat_access,
)

router = APIRouter(prefix="/billing", tags=["billing"])


def _bill_to_out(bill: MaintenanceBill) -> BillOut:
    amount_paid = sum(p.amount for p in bill.payments)
    out = BillOut.model_validate(bill)
    out.amount_paid = amount_paid
    return out


@router.post("/bills", response_model=BillOut)
def create_bill(
    payload: BillCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_flat_access(db, current_user, payload.flat_id)
    if not db.query(Flat).get(payload.flat_id):
        raise HTTPException(status_code=404, detail="Flat not found")
    existing = (
        db.query(MaintenanceBill)
        .filter(
            MaintenanceBill.flat_id == payload.flat_id,
            MaintenanceBill.period_month == payload.period_month,
            MaintenanceBill.period_year == payload.period_year,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Bill already exists for this period")
    bill = MaintenanceBill(**payload.model_dump())
    db.add(bill)
    db.commit()
    db.refresh(bill)
    return _bill_to_out(bill)


@router.post("/bills/generate-for-society", response_model=List[BillOut])
def generate_bills_for_society(
    payload: BillGenerateForSociety,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, payload.society_id)
    flats = (
        db.query(Flat)
        .join(Tower, Flat.tower_id == Tower.id)
        .filter(Tower.society_id == payload.society_id)
        .all()
    )
    if not flats:
        raise HTTPException(status_code=404, detail="No flats found for this society")

    created = []
    for flat in flats:
        existing = (
            db.query(MaintenanceBill)
            .filter(
                MaintenanceBill.flat_id == flat.id,
                MaintenanceBill.period_month == payload.period_month,
                MaintenanceBill.period_year == payload.period_year,
            )
            .first()
        )
        if existing:
            continue
        bill = MaintenanceBill(
            flat_id=flat.id,
            period_month=payload.period_month,
            period_year=payload.period_year,
            amount=payload.amount_per_flat,
            due_date=payload.due_date,
        )
        db.add(bill)
        created.append(bill)

    db.commit()
    for bill in created:
        db.refresh(bill)
    return [_bill_to_out(b) for b in created]


@router.get("/bills/flat/{flat_id}", response_model=List[BillOut])
def list_bills_for_flat(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, flat_id)
    bills = db.query(MaintenanceBill).filter(MaintenanceBill.flat_id == flat_id).all()
    return [_bill_to_out(b) for b in bills]


@router.get("/defaulters/{society_id}", response_model=List[BillOut])
def list_defaulters(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    bills = (
        db.query(MaintenanceBill)
        .join(Flat, MaintenanceBill.flat_id == Flat.id)
        .join(Tower, Flat.tower_id == Tower.id)
        .filter(
            Tower.society_id == society_id,
            MaintenanceBill.status.in_([BillStatus.pending, BillStatus.partial, BillStatus.overdue]),
            MaintenanceBill.due_date < date.today(),
        )
        .all()
    )
    return [_bill_to_out(b) for b in bills]


@router.delete("/bills/{bill_id}", status_code=204)
def delete_bill(
    bill_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    bill = db.query(MaintenanceBill).get(bill_id)
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    ensure_flat_access(db, current_user, bill.flat_id)
    if bill.payments:
        raise HTTPException(status_code=400, detail="Cannot delete a bill that has payments recorded")
    db.delete(bill)
    db.commit()


@router.post("/payments", response_model=PaymentOut)
def record_payment(
    payload: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be positive")

    bill = db.query(MaintenanceBill).get(payload.bill_id)
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    ensure_flat_access(db, current_user, bill.flat_id)

    # Sum existing payments BEFORE adding the new one, so the new amount is
    # counted exactly once (adding then re-summing bill.payments would double-count).
    existing_paid = sum(p.amount for p in bill.payments)

    payment = Payment(**payload.model_dump())
    db.add(payment)

    total_paid = existing_paid + payload.amount
    total_due = bill.amount + bill.late_fee
    if total_paid >= total_due:
        bill.status = BillStatus.paid
    elif total_paid > 0:
        bill.status = BillStatus.partial

    db.commit()
    db.refresh(payment)
    return payment
