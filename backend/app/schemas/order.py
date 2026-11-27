from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class BookSnapshot(BaseModel):
    id: str
    title: str
    author: str
    coverUrl: str
    categories: List[str] = []
    listingType: str = "for_sale"
    rating: float = 0.0
    price: float = 0.0

class OrderItemResponse(BaseModel):
    id: str
    book: BookSnapshot
    type: str
    quantity: int = 1
    price: float = 0.0
    # Phase 16C.2B Additive Pricing Fields
    transaction_type: Optional[str] = None
    unit_price_paise: Optional[int] = None
    rental_fee_paise: Optional[int] = None
    deposit_paise: Optional[int] = None
    total_item_paise: Optional[int] = None

class OrderResponse(BaseModel):
    id: str
    date: datetime
    status: str
    total_amount: float
    delivery_address: Optional[str] = None
    payment_method: Optional[str] = None
    payment_status: Optional[str] = None
    items: List[OrderItemResponse]
    tracking_id: Optional[str] = None
    carrier: Optional[str] = None
    estimated_delivery: Optional[datetime] = None
    shipping_status: Optional[str] = "pending"
    # Phase 16C.2B Additive Pricing & Fulfillment Fields
    items_total_paise: Optional[int] = None
    platform_fee_paise: Optional[int] = None
    shipping_fee_paise: Optional[int] = None
    deposit_total_paise: Optional[int] = None
    total_amount_paise: Optional[int] = None
    stock_deducted: Optional[bool] = None

class OrderStatsResponse(BaseModel):
    totalArchiveValue: float
    purchaseCount: int
    rentalCount: int
