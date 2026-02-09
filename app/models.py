from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field
from sqlalchemy import DateTime, Integer, String, Text, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


# --- SQLAlchemy ---


class Base(DeclarativeBase):
    pass


class Wisdom(Base):
    __tablename__ = "wisdom"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    author: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False, default="principle")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


# --- Pydantic schemas ---


class CategoryEnum(str, Enum):
    principle = "principle"
    fact = "fact"
    quote = "quote"
    proverb = "proverb"


class WisdomCreate(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000)
    author: str | None = Field(None, max_length=255)
    category: CategoryEnum = CategoryEnum.principle


class WisdomResponse(BaseModel):
    id: int
    text: str
    author: str | None
    category: str
    created_at: datetime

    model_config = {"from_attributes": True}
