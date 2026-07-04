from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Poll, PollOption, PollVote, User
from app.schemas import PollCreate, PollOut, PollOptionOut, PollVoteCreate
from app.security import get_current_user, require_admin, ensure_society_access

router = APIRouter(prefix="/polls", tags=["polls"])


def _poll_to_out(db: Session, poll: Poll, current_user: User) -> PollOut:
    options_out = []
    for opt in poll.options:
        vote_count = db.query(PollVote).filter(PollVote.option_id == opt.id).count()
        options_out.append(PollOptionOut(id=opt.id, text=opt.text, vote_count=vote_count))

    my_vote = (
        db.query(PollVote)
        .filter(PollVote.poll_id == poll.id, PollVote.user_id == current_user.id)
        .first()
    )

    return PollOut(
        id=poll.id,
        society_id=poll.society_id,
        question=poll.question,
        closes_at=poll.closes_at,
        created_at=poll.created_at,
        options=options_out,
        my_vote_option_id=my_vote.option_id if my_vote else None,
    )


@router.post("", response_model=PollOut)
def create_poll(
    payload: PollCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    ensure_society_access(current_user, payload.society_id)
    if len(payload.options) < 2:
        raise HTTPException(status_code=400, detail="A poll needs at least 2 options")

    poll = Poll(
        society_id=payload.society_id,
        created_by=current_user.id,
        question=payload.question,
        closes_at=payload.closes_at,
    )
    db.add(poll)
    db.flush()
    for text in payload.options:
        db.add(PollOption(poll_id=poll.id, text=text))
    db.commit()
    db.refresh(poll)
    return _poll_to_out(db, poll, current_user)


@router.get("/society/{society_id}", response_model=List[PollOut])
def list_polls(
    society_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_society_access(current_user, society_id)
    polls = (
        db.query(Poll)
        .filter(Poll.society_id == society_id)
        .order_by(Poll.created_at.desc())
        .all()
    )
    return [_poll_to_out(db, p, current_user) for p in polls]


@router.post("/{poll_id}/vote", response_model=PollOut)
def vote(
    poll_id: int,
    payload: PollVoteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    poll = db.query(Poll).get(poll_id)
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    ensure_society_access(current_user, poll.society_id)

    option = db.query(PollOption).get(payload.option_id)
    if not option or option.poll_id != poll_id:
        raise HTTPException(status_code=400, detail="Invalid option for this poll")

    existing = (
        db.query(PollVote)
        .filter(PollVote.poll_id == poll_id, PollVote.user_id == current_user.id)
        .first()
    )
    if existing:
        existing.option_id = payload.option_id
    else:
        db.add(PollVote(poll_id=poll_id, option_id=payload.option_id, user_id=current_user.id))

    db.commit()
    db.refresh(poll)
    return _poll_to_out(db, poll, current_user)
