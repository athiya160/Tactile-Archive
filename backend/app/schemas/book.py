from pydantic import BaseModel
from typing import Optional, List

class BookCreate(BaseModel):
    title: str
    author: str
    description: Optional[str] = None
    price: Optional[float] = 0.0
    category: Optional[str] = None
    cover_url: Optional[str] = None
    coverUrl: Optional[str] = None
    stock: Optional[int] = 1
    publisher: Optional[str] = None
    language: Optional[str] = None
    isbn: Optional[str] = None
    edition: Optional[str] = None
    pages: Optional[str] = None
    condition: Optional[str] = None
    images: Optional[List[str]] = None
    listingType: Optional[str] = None
    listing_type: Optional[str] = None
    pickupAddress: Optional[str] = None
    pickup_address: Optional[str] = None

    @property
    def resolved_cover_url(self) -> Optional[str]:
        return self.cover_url or self.coverUrl

    @property
    def resolved_pickup_address(self) -> Optional[str]:
        return self.pickup_address or self.pickupAddress

class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    category: Optional[str] = None
    cover_url: Optional[str] = None
    publisher: Optional[str] = None
    language: Optional[str] = None
    isbn: Optional[str] = None
    edition: Optional[str] = None
    pages: Optional[str] = None
    condition: Optional[str] = None

class BookResponse(BaseModel):
    id: int
    title: str
    author: str
    description: Optional[str] = None
    price: float
    rating: float
    category: Optional[str] = None
    publisher: Optional[str] = None
    language: Optional[str] = None
    isbn: Optional[str] = None
    edition: Optional[str] = None
    pages: Optional[str] = None
    condition: Optional[str] = None
    owner_id: int
    image_url: str
    cover_url: Optional[str] = None
    approval_status: Optional[str] = "approved"
    condition_verification: Optional[str] = "verified"
    verification_notes: Optional[str] = ""
    images: Optional[List[str]] = []
    listingType: Optional[str] = "forSale"
    originalPrice: Optional[float] = None
    discountPercentage: Optional[float] = None
    isStaffPick: Optional[bool] = False
    categories: Optional[List[str]] = []

    class Config:
        from_attributes = True