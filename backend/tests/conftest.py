import os
import sys
import tempfile

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Use a temp-file SQLite DB shared by every connection, and force test config
# BEFORE importing the app (env vars take priority over .env in pydantic-settings).
_DB_FD, _DB_PATH = tempfile.mkstemp(suffix=".db")
os.close(_DB_FD)
os.environ["DATABASE_URL"] = f"sqlite:///{_DB_PATH}"
os.environ["SECRET_KEY"] = "test-secret-key"

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402
from app import models  # noqa: E402
from app.security import hash_password  # noqa: E402

engine = create_engine(
    f"sqlite:///{_DB_PATH}",
    connect_args={"check_same_thread": False},
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def _override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture()
def db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    yield session
    session.close()


@pytest.fixture()
def client():
    return TestClient(app)


@pytest.fixture()
def seeded(db):
    """Two societies; society A has a secretary, a resident, a tower + flat with
    the resident as member. Society B has its own secretary. Returns ids/tokens."""
    soc_a = models.Society(name="Alpha CHS", city="Pune")
    soc_b = models.Society(name="Beta CHS", city="Mumbai")
    db.add_all([soc_a, soc_b])
    db.flush()

    tower = models.Tower(society_id=soc_a.id, name="Tower A")
    db.add(tower)
    db.flush()
    flat = models.Flat(tower_id=tower.id, number="A-101")
    db.add(flat)
    db.flush()

    sec_a = models.User(email="sec_a@x.com", hashed_password=hash_password("pw"),
                        full_name="Sec A", role=models.UserRole.secretary, society_id=soc_a.id)
    res_a = models.User(email="res_a@x.com", hashed_password=hash_password("pw"),
                        full_name="Res A", role=models.UserRole.resident, society_id=soc_a.id)
    sec_b = models.User(email="sec_b@x.com", hashed_password=hash_password("pw"),
                        full_name="Sec B", role=models.UserRole.secretary, society_id=soc_b.id)
    db.add_all([sec_a, res_a, sec_b])
    db.flush()
    db.add(models.Membership(user_id=res_a.id, flat_id=flat.id,
                             relation=models.MemberRelation.owner, is_primary=True))
    db.commit()

    return {
        "soc_a": soc_a.id, "soc_b": soc_b.id, "tower": tower.id, "flat": flat.id,
        "sec_a": sec_a.id, "res_a": res_a.id, "sec_b": sec_b.id,
    }

# NOTE: keep login/auth helpers defined INSIDE each test module, not here.
# Importing from conftest re-executes this file as a second module, which would
# create a second temp DB and clobber the dependency override.
