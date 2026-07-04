from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import User, UserRole, Flat, Tower, Membership

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

ALGORITHM = "HS256"

# Roles that may perform committee/management actions.
ADMIN_ROLES = {UserRole.admin, UserRole.secretary, UserRole.treasurer, UserRole.committee}


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        email: Optional[str] = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require a committee-level role (admin/secretary/treasurer/committee)."""
    if current_user.role not in ADMIN_ROLES:
        raise HTTPException(status_code=403, detail="Committee access required")
    return current_user


def ensure_society_access(user: User, society_id: int) -> None:
    """Reject access to a society the user is not a member of."""
    if user.society_id != society_id:
        raise HTTPException(status_code=403, detail="No access to this society")


def society_id_for_flat(db: Session, flat_id: int) -> int:
    """Resolve a flat's society, or 404 if the flat doesn't exist."""
    flat = db.query(Flat).get(flat_id)
    if not flat:
        raise HTTPException(status_code=404, detail="Flat not found")
    tower = db.query(Tower).get(flat.tower_id)
    return tower.society_id


def ensure_flat_access(db: Session, user: User, flat_id: int) -> None:
    """Residents may only touch flats they belong to; committee may touch any
    flat in their own society."""
    society_id = society_id_for_flat(db, flat_id)
    if user.role in ADMIN_ROLES:
        ensure_society_access(user, society_id)
        return
    membership = (
        db.query(Membership)
        .filter(Membership.user_id == user.id, Membership.flat_id == flat_id)
        .first()
    )
    if not membership:
        raise HTTPException(status_code=403, detail="No access to this flat")
