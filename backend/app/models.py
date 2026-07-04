import enum
from datetime import datetime

from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    ForeignKey,
    DateTime,
    Enum,
    Date,
    Boolean,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.database import Base


class UserRole(str, enum.Enum):
    admin = "admin"
    secretary = "secretary"
    treasurer = "treasurer"
    committee = "committee"
    resident = "resident"


class MemberRelation(str, enum.Enum):
    owner = "owner"
    tenant = "tenant"


class BillStatus(str, enum.Enum):
    pending = "pending"
    partial = "partial"
    paid = "paid"
    overdue = "overdue"


class PaymentMethod(str, enum.Enum):
    upi = "upi"
    bank_transfer = "bank_transfer"
    cash = "cash"
    cheque = "cheque"
    razorpay = "razorpay"


class ComplaintCategory(str, enum.Enum):
    plumbing = "plumbing"
    electrical = "electrical"
    carpentry = "carpentry"
    cleaning = "cleaning"
    security = "security"
    other = "other"


class ComplaintStatus(str, enum.Enum):
    open = "open"
    in_progress = "in_progress"
    resolved = "resolved"


class Society(Base):
    __tablename__ = "societies"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    registration_number = Column(String, unique=True, nullable=True)
    address = Column(String)
    city = Column(String)
    state = Column(String, default="Maharashtra")
    created_at = Column(DateTime, default=datetime.utcnow)

    towers = relationship("Tower", back_populates="society", cascade="all, delete-orphan")
    users = relationship("User", back_populates="society")
    documents = relationship("Document", back_populates="society", cascade="all, delete-orphan")


class Tower(Base):
    __tablename__ = "towers"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    name = Column(String, nullable=False)

    society = relationship("Society", back_populates="towers")
    flats = relationship("Flat", back_populates="tower", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("society_id", "name", name="uq_tower_per_society"),)


class Flat(Base):
    __tablename__ = "flats"

    id = Column(Integer, primary_key=True)
    tower_id = Column(Integer, ForeignKey("towers.id"), nullable=False)
    number = Column(String, nullable=False)
    floor = Column(Integer)
    area_sqft = Column(Float)

    tower = relationship("Tower", back_populates="flats")
    memberships = relationship("Membership", back_populates="flat", cascade="all, delete-orphan")
    bills = relationship("MaintenanceBill", back_populates="flat", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("tower_id", "number", name="uq_flat_per_tower"),)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=True)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    phone = Column(String)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.resident)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    society = relationship("Society", back_populates="users")
    memberships = relationship("Membership", back_populates="user", cascade="all, delete-orphan")
    documents_uploaded = relationship("Document", back_populates="uploaded_by_user")


class Membership(Base):
    __tablename__ = "memberships"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    relation = Column(Enum(MemberRelation), nullable=False, default=MemberRelation.owner)
    is_primary = Column(Boolean, default=True)

    user = relationship("User", back_populates="memberships")
    flat = relationship("Flat", back_populates="memberships")

    __table_args__ = (UniqueConstraint("user_id", "flat_id", name="uq_user_per_flat"),)


class MaintenanceBill(Base):
    __tablename__ = "maintenance_bills"

    id = Column(Integer, primary_key=True)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    period_month = Column(Integer, nullable=False)
    period_year = Column(Integer, nullable=False)
    amount = Column(Float, nullable=False)
    late_fee = Column(Float, default=0)
    due_date = Column(Date, nullable=False)
    status = Column(Enum(BillStatus), nullable=False, default=BillStatus.pending)
    created_at = Column(DateTime, default=datetime.utcnow)

    flat = relationship("Flat", back_populates="bills")
    payments = relationship("Payment", back_populates="bill", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("flat_id", "period_month", "period_year", name="uq_bill_per_period"),
    )


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    bill_id = Column(Integer, ForeignKey("maintenance_bills.id"), nullable=False)
    amount = Column(Float, nullable=False)
    method = Column(Enum(PaymentMethod), nullable=False, default=PaymentMethod.upi)
    reference_id = Column(String, nullable=True)
    paid_at = Column(DateTime, default=datetime.utcnow)

    bill = relationship("MaintenanceBill", back_populates="payments")


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    category = Column(String, nullable=False)
    title = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    expiry_date = Column(Date, nullable=True)

    society = relationship("Society", back_populates="documents")
    uploaded_by_user = relationship("User", back_populates="documents_uploaded")


class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    raised_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    category = Column(Enum(ComplaintCategory), nullable=False, default=ComplaintCategory.other)
    title = Column(String, nullable=False)
    description = Column(Text)
    status = Column(Enum(ComplaintStatus), nullable=False, default=ComplaintStatus.open)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Notice(Base):
    __tablename__ = "notices"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    posted_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    category = Column(String, default="general")
    title = Column(String, nullable=False)
    body = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
