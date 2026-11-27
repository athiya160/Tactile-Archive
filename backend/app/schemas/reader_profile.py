from pydantic import BaseModel
from typing import Optional, List

class ReaderProfilePayload(BaseModel):
    genres: Optional[List[str]] = []
    favorite_authors: Optional[List[str]] = []
    reading_goal: Optional[str] = "Read 12 books this year"
    preferred_duration: Optional[int] = 30
    favorite_moods: Optional[List[str]] = []
    reading_frequency: Optional[str] = "Daily"

class ReaderProfileResponse(BaseModel):
    id: int
    user_id: int
    genres: Optional[List[str]] = []
    favorite_authors: Optional[List[str]] = []
    reading_goal: Optional[str] = None
    preferred_duration: int = 30
    favorite_moods: Optional[List[str]] = []
    reading_frequency: str = "Daily"

    class Config:
        from_attributes = True
