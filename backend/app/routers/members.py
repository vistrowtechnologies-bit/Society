from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, Flat, Membership, Tower, Society
from app.schemas import MembershipCreate, MembershipOut, UserOut, MyFlatOut
from app.security import (
    get_current_user,
    require_admin,
    ensure_society_access,
    ensure_flat_access,
    society_id_for_flat,
    ADMIN_ROLES,
)

router = APIRouter(prefix="/members", tags=["members"])


@router.get("/me/flats", response_model=List[MyFlatOut])
def my_flats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    memberships = db.query(Membership).filter(Membership.user_id == current_user.id).all()
    results = []
    for m in memberships:
        flat = db.query(Flat).get(m.flat_id)
        tower = db.query(Tower).get(flat.tower_id)
        society = db.query(Society).get(tower.society_id)
        results.append(
            MyFlatOut(
                flat_id=flat.id,
                society_id=society.id,
                flat_number=flat.number,
                tower_name=tower.name,
                society_name=society.name,
                relation=m.relation,
            )
        )
    return results


@router.post("", response_model=MembershipOut)
def add_member(
    payload: MembershipCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not db.query(User).get(payload.user_id):
        raise HTTPException(status_code=404, detail="User not found")
    if not db.query(Flat).get(payload.flat_id):
        raise HTTPException(status_code=404, detail="Flat not found")

    # A resident may add ONLY themselves (self-join during onboarding); a
    # committee member may add anyone, but only to a flat in their own society.
    is_self_join = payload.user_id == current_user.id
    if current_user.role in ADMIN_ROLES:
        ensure_society_access(current_user, society_id_for_flat(db, payload.flat_id))
    elif not is_self_join:
        raise HTTPException(status_code=403, detail="You can only add yourself to a flat")

    membership = Membership(**payload.model_dump())
    db.add(membership)
    db.commit()
    db.refresh(membership)
    return membership


@router.get("/flats/{flat_id}", response_model=List[UserOut])
def list_flat_members(
    flat_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_flat_access(db, current_user, flat_id)
    memberships = db.query(Membership).filter(Membership.flat_id == flat_id).all()
    return [m.user for m in memberships]


@router.get("/society/{society_id}", response_model=List[UserOut])
def list_society_members(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, society_id)
    return db.query(User).filter(User.society_id == society_id).all()
