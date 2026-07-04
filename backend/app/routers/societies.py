from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Society, Tower, Flat, User
from app.schemas import (
    SocietyCreate,
    SocietyOut,
    TowerCreate,
    TowerOut,
    FlatCreate,
    FlatOut,
)
from app.security import get_current_user, require_admin, ensure_society_access

router = APIRouter(prefix="/societies", tags=["societies"])


# NOTE: the GET list endpoints below stay public because the sign-up flow needs
# to show society/tower/flat dropdowns before the user has an account. Creation
# endpoints are gated. The first society + secretary are provisioned via
# seed_admin.py (server operator), after which that secretary manages structure.
@router.post("", response_model=SocietyOut)
def create_society(
    payload: SocietyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    society = Society(**payload.model_dump())
    db.add(society)
    db.commit()
    db.refresh(society)
    return society


@router.get("", response_model=List[SocietyOut])
def list_societies(db: Session = Depends(get_db)):
    return db.query(Society).all()


@router.get("/{society_id}", response_model=SocietyOut)
def get_society(society_id: int, db: Session = Depends(get_db)):
    society = db.query(Society).get(society_id)
    if not society:
        raise HTTPException(status_code=404, detail="Society not found")
    return society


@router.post("/towers", response_model=TowerOut)
def create_tower(
    payload: TowerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, payload.society_id)
    if not db.query(Society).get(payload.society_id):
        raise HTTPException(status_code=404, detail="Society not found")
    tower = Tower(**payload.model_dump())
    db.add(tower)
    db.commit()
    db.refresh(tower)
    return tower


@router.get("/{society_id}/towers", response_model=List[TowerOut])
def list_towers(society_id: int, db: Session = Depends(get_db)):
    return db.query(Tower).filter(Tower.society_id == society_id).all()


@router.post("/flats", response_model=FlatOut)
def create_flat(
    payload: FlatCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    tower = db.query(Tower).get(payload.tower_id)
    if not tower:
        raise HTTPException(status_code=404, detail="Tower not found")
    ensure_society_access(current_user, tower.society_id)
    flat = Flat(**payload.model_dump())
    db.add(flat)
    db.commit()
    db.refresh(flat)
    return flat


@router.get("/towers/{tower_id}/flats", response_model=List[FlatOut])
def list_flats(tower_id: int, db: Session = Depends(get_db)):
    return db.query(Flat).filter(Flat.tower_id == tower_id).all()
