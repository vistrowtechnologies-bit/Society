from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Vehicle, Flat, Tower, User
from app.schemas import VehicleCreate, VehicleOut
from app.security import get_current_user, require_admin, ensure_flat_access, ensure_society_access

router = APIRouter(prefix="/vehicles", tags=["vehicles"])


@router.post("", response_model=VehicleOut)
def add_vehicle(
    payload: VehicleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, payload.flat_id)
    vehicle = Vehicle(**payload.model_dump())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


@router.get("/flat/{flat_id}", response_model=List[VehicleOut])
def list_flat_vehicles(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, flat_id)
    return db.query(Vehicle).filter(Vehicle.flat_id == flat_id).all()


@router.get("/society/{society_id}", response_model=List[VehicleOut])
def list_society_vehicles(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    return (
        db.query(Vehicle)
        .join(Flat, Vehicle.flat_id == Flat.id)
        .join(Tower, Flat.tower_id == Tower.id)
        .filter(Tower.society_id == society_id)
        .limit(500)
        .all()
    )


@router.delete("/{vehicle_id}", status_code=204)
def delete_vehicle(
    vehicle_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    vehicle = db.query(Vehicle).get(vehicle_id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    ensure_flat_access(db, current_user, vehicle.flat_id)
    db.delete(vehicle)
    db.commit()
