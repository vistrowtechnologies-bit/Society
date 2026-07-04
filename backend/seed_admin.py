"""Create or promote an admin/secretary account.

Public /auth/register only ever creates residents (so nobody can grant
themselves elevated access). Use this script to bootstrap or promote a
committee member from a trusted context (the server operator's shell).

Usage:
    ./venv/bin/python seed_admin.py <email> <password> <full_name> <role> <society_id>

Example:
    ./venv/bin/python seed_admin.py secretary@sunshine.chs test1234 "Ramesh Kulkarni" secretary 1
"""
import sys

from app.database import SessionLocal
from app.models import User, Society, UserRole
from app.security import hash_password


def main():
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(1)

    email, password, full_name, role_str, society_id_str = sys.argv[1:6]
    try:
        role = UserRole(role_str)
    except ValueError:
        print(f"Invalid role '{role_str}'. Must be one of: {', '.join(r.value for r in UserRole)}")
        sys.exit(1)

    society_id = int(society_id_str)
    db = SessionLocal()
    try:
        if not db.query(Society).get(society_id):
            print(f"Society {society_id} does not exist.")
            sys.exit(1)

        user = db.query(User).filter(User.email == email).first()
        if user:
            user.role = role
            user.society_id = society_id
            action = "Promoted"
        else:
            user = User(
                email=email,
                hashed_password=hash_password(password),
                full_name=full_name,
                role=role,
                society_id=society_id,
            )
            db.add(user)
            action = "Created"
        db.commit()
        db.refresh(user)
        print(f"{action} {user.email} as {user.role.value} for society {society_id}.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
