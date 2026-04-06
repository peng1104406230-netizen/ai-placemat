from sqlalchemy.orm import Session

from app.models.user import User


class UserService:
    def __init__(self, db: Session):
        self.db = db

    def get_or_create_user(self, anonymous_user_id: str) -> User:
        user = (
            self.db.query(User)
            .filter(User.anonymous_user_id == anonymous_user_id)
            .one_or_none()
        )
        if user is not None:
            return user

        user = User(anonymous_user_id=anonymous_user_id)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
