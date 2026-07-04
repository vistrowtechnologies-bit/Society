from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Amenity, AmenityBooking, BookingStatus, User
from app.schemas import AmenityCreate, AmenityOut, AmenityBookingCreate, AmenityBookingOut
from app.security import get_current_user, require_admin, ensure_society_access, ensure_flat_access

router = APIRouter(prefix="/amenities", tags=["amenities"])


@router.post("", response_model=AmenityOut)
def create_amenity(
    payload: AmenityCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    if current_user.society_id is None:
        raise HTTPException(status_code=400, detail="No society associated with this account")
    amenity = Amenity(society_id=current_user.society_id, **payload.model_dump())
    db.add(amenity)
    db.commit()
    db.refresh(amenity)
    return amenity


@router.get("/society/{society_id}", response_model=List[AmenityOut])
def list_amenities(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_society_access(current_user, society_id)
    return db.query(Amenity).filter(Amenity.society_id == society_id).all()


@router.delete("/{amenity_id}", status_code=204)
def delete_amenity(
    amenity_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    amenity = db.query(Amenity).get(amenity_id)
    if not amenity:
        raise HTTPException(status_code=404, detail="Amenity not found")
    ensure_society_access(current_user, amenity.society_id)
    db.delete(amenity)
    db.commit()


@router.post("/bookings", response_model=AmenityBookingOut)
def create_booking(
    payload: AmenityBookingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, payload.flat_id)
    amenity = db.query(Amenity).get(payload.amenity_id)
    if not amenity:
        raise HTTPException(status_code=404, detail="Amenity not found")
    ensure_society_access(current_user, amenity.society_id)

    if payload.start_time >= payload.end_time:
        raise HTTPException(status_code=400, detail="start_time must be before end_time")

    # Reject overlapping active bookings for the same amenity/date/time range.
    overlap = (
        db.query(AmenityBooking)
        .filter(
            AmenityBooking.amenity_id == payload.amenity_id,
            AmenityBooking.booking_date == payload.booking_date,
            AmenityBooking.status == BookingStatus.booked,
            AmenityBooking.start_time < payload.end_time,
            AmenityBooking.end_time > payload.start_time,
        )
        .first()
    )
    if overlap:
        raise HTTPException(status_code=409, detail="This slot is already booked")

    booking = AmenityBooking(booked_by=current_user.id, **payload.model_dump())
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


@router.get("/bookings/amenity/{amenity_id}", response_model=List[AmenityBookingOut])
def list_amenity_bookings(
    amenity_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    amenity = db.query(Amenity).get(amenity_id)
    if not amenity:
        raise HTTPException(status_code=404, detail="Amenity not found")
    ensure_society_access(current_user, amenity.society_id)
    return (
        db.query(AmenityBooking)
        .filter(AmenityBooking.amenity_id == amenity_id, AmenityBooking.status == BookingStatus.booked)
        .all()
    )


@router.get("/bookings/flat/{flat_id}", response_model=List[AmenityBookingOut])
def list_flat_bookings(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, flat_id)
    return (
        db.query(AmenityBooking)
        .filter(AmenityBooking.flat_id == flat_id)
        .order_by(AmenityBooking.booking_date.desc())
        .all()
    )


@router.delete("/bookings/{booking_id}", status_code=204)
def cancel_booking(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    booking = db.query(AmenityBooking).get(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    ensure_flat_access(db, current_user, booking.flat_id)
    booking.status = BookingStatus.cancelled
    db.commit()
