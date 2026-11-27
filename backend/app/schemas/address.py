from pydantic import BaseModel

class AddressCreate(BaseModel):
    label: str
    recipientName: str
    phoneNumber: str
    street: str
    city: str
    state: str
    zipCode: str
    isDefault: bool = False

class AddressResponse(BaseModel):
    id: str
    label: str
    recipientName: str
    phoneNumber: str
    street: str
    city: str
    state: str
    zipCode: str
    isDefault: bool

    class Config:
        from_attributes = True
