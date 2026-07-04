from datetime import datetime, date
from typing import Optional

from pydantic import BaseModel, EmailStr

from app.models import (
    UserRole,
    MemberRelation,
    BillStatus,
    PaymentMethod,
    ComplaintCategory,
    ComplaintStatus,
    VisitorStatus,
    VehicleType,
    StaffRole,
    BookingStatus,
    SOSStatus,
)


class SocietyCreate(BaseModel):
    name: str
    registration_number: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: str = "Maharashtra"


class SocietyOut(SocietyCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class TowerCreate(BaseModel):
    society_id: int
    name: str


class TowerOut(TowerCreate):
    id: int

    class Config:
        from_attributes = True


class FlatCreate(BaseModel):
    tower_id: int
    number: str
    floor: Optional[int] = None
    area_sqft: Optional[float] = None


class FlatOut(FlatCreate):
    id: int

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: Optional[str] = None
    role: UserRole = UserRole.resident
    society_id: Optional[int] = None


class UserOut(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: UserRole
    society_id: Optional[int] = None
    is_active: bool

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MembershipCreate(BaseModel):
    user_id: int
    flat_id: int
    relation: MemberRelation = MemberRelation.owner
    is_primary: bool = True


class MembershipOut(MembershipCreate):
    id: int

    class Config:
        from_attributes = True


class BillCreate(BaseModel):
    flat_id: int
    period_month: int
    period_year: int
    amount: float
    due_date: date


class BillGenerateForSociety(BaseModel):
    society_id: int
    period_month: int
    period_year: int
    amount_per_flat: float
    due_date: date


class BillOut(BaseModel):
    id: int
    flat_id: int
    period_month: int
    period_year: int
    amount: float
    late_fee: float
    due_date: date
    status: BillStatus
    amount_paid: float = 0

    class Config:
        from_attributes = True


class PaymentCreate(BaseModel):
    bill_id: int
    amount: float
    method: PaymentMethod = PaymentMethod.upi
    reference_id: Optional[str] = None


class PaymentOut(PaymentCreate):
    id: int
    paid_at: datetime

    class Config:
        from_attributes = True


class DocumentOut(BaseModel):
    id: int
    society_id: int
    category: str
    title: str
    file_path: str
    uploaded_at: datetime
    expiry_date: Optional[date] = None

    class Config:
        from_attributes = True


class ComplaintCreate(BaseModel):
    flat_id: int
    category: ComplaintCategory = ComplaintCategory.other
    title: str
    description: Optional[str] = None


class ComplaintOut(BaseModel):
    id: int
    society_id: int
    flat_id: int
    raised_by: int
    category: ComplaintCategory
    title: str
    description: Optional[str] = None
    status: ComplaintStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ComplaintStatusUpdate(BaseModel):
    status: ComplaintStatus


class NoticeCreate(BaseModel):
    society_id: int
    category: str = "general"
    title: str
    body: str


class NoticeUpdate(BaseModel):
    category: Optional[str] = None
    title: Optional[str] = None
    body: Optional[str] = None


class NoticeOut(BaseModel):
    id: int
    society_id: int
    posted_by: Optional[int] = None
    category: str
    title: str
    body: str
    created_at: datetime

    class Config:
        from_attributes = True


class MyFlatOut(BaseModel):
    flat_id: int
    society_id: int
    flat_number: str
    tower_name: str
    society_name: str
    relation: MemberRelation


# ---- Visitor management ----

class VisitorCreate(BaseModel):
    flat_id: int
    name: str
    phone: Optional[str] = None
    purpose: str = "guest"


class VisitorOut(BaseModel):
    id: int
    society_id: int
    flat_id: int
    name: str
    phone: Optional[str] = None
    purpose: str
    status: VisitorStatus
    created_at: datetime
    checked_in_at: Optional[datetime] = None
    checked_out_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class VisitorStatusUpdate(BaseModel):
    status: VisitorStatus


# ---- Vehicles ----

class VehicleCreate(BaseModel):
    flat_id: int
    plate_number: str
    vehicle_type: VehicleType = VehicleType.car
    parking_slot: Optional[str] = None


class VehicleOut(BaseModel):
    id: int
    flat_id: int
    plate_number: str
    vehicle_type: VehicleType
    parking_slot: Optional[str] = None

    class Config:
        from_attributes = True


# ---- Staff ----

class StaffCreate(BaseModel):
    flat_id: Optional[int] = None
    full_name: str
    phone: Optional[str] = None
    role: StaffRole = StaffRole.other


class StaffOut(BaseModel):
    id: int
    society_id: int
    flat_id: Optional[int] = None
    full_name: str
    phone: Optional[str] = None
    role: StaffRole
    is_verified: bool

    class Config:
        from_attributes = True


class StaffVerifyUpdate(BaseModel):
    is_verified: bool


class StaffAttendanceOut(BaseModel):
    id: int
    staff_id: int
    checked_in_at: datetime
    checked_out_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---- Amenities ----

class AmenityCreate(BaseModel):
    name: str
    description: Optional[str] = None
    capacity: Optional[int] = None
    open_time: str = "06:00"
    close_time: str = "22:00"


class AmenityOut(BaseModel):
    id: int
    society_id: int
    name: str
    description: Optional[str] = None
    capacity: Optional[int] = None
    open_time: str
    close_time: str

    class Config:
        from_attributes = True


class AmenityBookingCreate(BaseModel):
    amenity_id: int
    flat_id: int
    booking_date: date
    start_time: str
    end_time: str


class AmenityBookingOut(BaseModel):
    id: int
    amenity_id: int
    flat_id: int
    booked_by: int
    booking_date: date
    start_time: str
    end_time: str
    status: BookingStatus

    class Config:
        from_attributes = True


# ---- SOS ----

class SOSCreate(BaseModel):
    flat_id: int
    message: Optional[str] = None


class SOSOut(BaseModel):
    id: int
    society_id: int
    flat_id: int
    raised_by: int
    message: Optional[str] = None
    status: SOSStatus
    created_at: datetime
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---- Polls ----

class PollCreate(BaseModel):
    society_id: int
    question: str
    options: list[str]
    closes_at: Optional[datetime] = None


class PollOptionOut(BaseModel):
    id: int
    text: str
    vote_count: int = 0

    class Config:
        from_attributes = True


class PollOut(BaseModel):
    id: int
    society_id: int
    question: str
    closes_at: Optional[datetime] = None
    created_at: datetime
    options: list[PollOptionOut]
    my_vote_option_id: Optional[int] = None

    class Config:
        from_attributes = True


class PollVoteCreate(BaseModel):
    option_id: int
