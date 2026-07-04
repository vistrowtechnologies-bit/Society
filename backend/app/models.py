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
    guard = "guard"


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


# ---- Visitor management ----

class VisitorStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    denied = "denied"
    checked_in = "checked_in"
    checked_out = "checked_out"


class Visitor(Base):
    __tablename__ = "visitors"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    name = Column(String, nullable=False)
    phone = Column(String)
    purpose = Column(String, default="guest")
    status = Column(Enum(VisitorStatus), nullable=False, default=VisitorStatus.pending)
    pre_approved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    checked_in_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    checked_in_at = Column(DateTime, nullable=True)
    checked_out_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


# ---- Vehicle & parking ----

class VehicleType(str, enum.Enum):
    car = "car"
    bike = "bike"
    other = "other"


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    plate_number = Column(String, nullable=False)
    vehicle_type = Column(Enum(VehicleType), nullable=False, default=VehicleType.car)
    parking_slot = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (UniqueConstraint("flat_id", "plate_number", name="uq_vehicle_per_flat"),)


# ---- Staff / helper management ----

class StaffRole(str, enum.Enum):
    maid = "maid"
    driver = "driver"
    cook = "cook"
    nanny = "nanny"
    other = "other"


class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=True)
    full_name = Column(String, nullable=False)
    phone = Column(String)
    role = Column(Enum(StaffRole), nullable=False, default=StaffRole.other)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class StaffAttendance(Base):
    __tablename__ = "staff_attendance"

    id = Column(Integer, primary_key=True)
    staff_id = Column(Integer, ForeignKey("staff.id"), nullable=False)
    checked_in_at = Column(DateTime, default=datetime.utcnow)
    checked_out_at = Column(DateTime, nullable=True)


# ---- Amenity booking ----

class Amenity(Base):
    __tablename__ = "amenities"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    capacity = Column(Integer, nullable=True)
    open_time = Column(String, default="06:00")
    close_time = Column(String, default="22:00")
    created_at = Column(DateTime, default=datetime.utcnow)


class BookingStatus(str, enum.Enum):
    booked = "booked"
    cancelled = "cancelled"


class AmenityBooking(Base):
    __tablename__ = "amenity_bookings"

    id = Column(Integer, primary_key=True)
    amenity_id = Column(Integer, ForeignKey("amenities.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    booked_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    booking_date = Column(Date, nullable=False)
    start_time = Column(String, nullable=False)
    end_time = Column(String, nullable=False)
    status = Column(Enum(BookingStatus), nullable=False, default=BookingStatus.booked)
    created_at = Column(DateTime, default=datetime.utcnow)


# ---- Panic / SOS ----

class SOSStatus(str, enum.Enum):
    active = "active"
    resolved = "resolved"


class SOSAlert(Base):
    __tablename__ = "sos_alerts"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    flat_id = Column(Integer, ForeignKey("flats.id"), nullable=False)
    raised_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(String, nullable=True)
    status = Column(Enum(SOSStatus), nullable=False, default=SOSStatus.active)
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    resolved_by = Column(Integer, ForeignKey("users.id"), nullable=True)


# ---- Polls / surveys ----

class Poll(Base):
    __tablename__ = "polls"

    id = Column(Integer, primary_key=True)
    society_id = Column(Integer, ForeignKey("societies.id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    question = Column(String, nullable=False)
    closes_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    options = relationship("PollOption", back_populates="poll", cascade="all, delete-orphan")


class PollOption(Base):
    __tablename__ = "poll_options"

    id = Column(Integer, primary_key=True)
    poll_id = Column(Integer, ForeignKey("polls.id"), nullable=False)
    text = Column(String, nullable=False)

    poll = relationship("Poll", back_populates="options")
    votes = relationship("PollVote", back_populates="option", cascade="all, delete-orphan")


class PollVote(Base):
    __tablename__ = "poll_votes"

    id = Column(Integer, primary_key=True)
    poll_id = Column(Integer, ForeignKey("polls.id"), nullable=False)
    option_id = Column(Integer, ForeignKey("poll_options.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    option = relationship("PollOption", back_populates="votes")

    __table_args__ = (UniqueConstraint("poll_id", "user_id", name="uq_one_vote_per_poll"),)
