from pydantic import BaseModel, root_validator
from typing import List, Optional

class CartItemCreate(BaseModel):
    bookId: Optional[int] = None
    book_id: Optional[int] = None
    isPurchase: bool = True
    is_purchase: Optional[bool] = None
    rentalDays: Optional[int] = None
    rental_days: Optional[int] = None
    quantity: Optional[int] = 1

    @root_validator(pre=True)
    def validate_book_id(cls, values):
        if not isinstance(values, dict):
            return values
        b_id = values.get("bookId") if values.get("bookId") is not None else values.get("book_id")
        if b_id is None:
            raise ValueError("bookId or book_id is required")
        return values

    @property
    def target_book_id(self) -> int:
        val = self.bookId if self.bookId is not None else self.book_id
        return int(val)

    @property
    def resolved_is_purchase(self) -> bool:
        if self.is_purchase is not None:
            return self.is_purchase
        return self.isPurchase

    @property
    def resolved_rental_days(self) -> Optional[int]:
        if self.rental_days is not None:
            return self.rental_days
        return self.rentalDays

class CartItemResponse(BaseModel):
    id: str
    bookId: str
    title: str
    author: str
    coverUrl: str
    price: float
    isPurchase: bool
    rentalDays: Optional[int] = None
    quantity: int

    class Config:
        from_attributes = True

class CartItemUpdate(BaseModel):
    quantity: int

class CartDeliveryUpdate(BaseModel):
    address: str
    recipient: str

class CartResponse(BaseModel):
    items: List[CartItemResponse]
    deliveryAddress: Optional[str] = None
    recipientName: Optional[str] = None
    archiveFee: float
    shippingFee: float

    class Config:
        from_attributes = True
