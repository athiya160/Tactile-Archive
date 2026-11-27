from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.address import Address
from app.models.cart import Cart
from app.models.user import User
from app.schemas.address import AddressCreate, AddressResponse
from app.api.auth import get_current_user
from typing import List

router = APIRouter()

# DB Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 🔓 Get Saved Addresses (Protected)
@router.get("/addresses", response_model=List[AddressResponse])
def get_addresses(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    addresses = db.query(Address).filter(Address.user_id == user.id).all()
    return [
        AddressResponse(
            id=str(addr.id),
            label=addr.label,
            recipientName=addr.recipient_name,
            phoneNumber=addr.phone_number,
            street=addr.street,
            city=addr.city,
            state=addr.state,
            zipCode=addr.zip_code,
            isDefault=addr.is_default
        )
        for addr in addresses
    ]

# 🔒 Add Address (Protected)
@router.post("/addresses", response_model=AddressResponse)
def add_address(
    data: AddressCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    # If the new address is set as default, mark other user addresses as non-default
    if data.isDefault:
        db.query(Address).filter(Address.user_id == user.id).update({"is_default": False})

    new_addr = Address(
        user_id=user.id,
        label=data.label,
        recipient_name=data.recipientName,
        phone_number=data.phoneNumber,
        street=data.street,
        city=data.city,
        state=data.state,
        zip_code=data.zipCode,
        is_default=data.isDefault
    )
    db.add(new_addr)
    db.commit()
    db.refresh(new_addr)

    # Also automatically update the active cart with this address if it's default or if the cart currently has no address!
    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if not cart:
        cart = Cart(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    
    if data.isDefault or not cart.delivery_address:
        cart.delivery_address = f"{new_addr.street}, {new_addr.city}, {new_addr.state} {new_addr.zip_code}"
        cart.recipient_name = new_addr.recipient_name
        db.commit()

    return AddressResponse(
        id=str(new_addr.id),
        label=new_addr.label,
        recipientName=new_addr.recipient_name,
        phoneNumber=new_addr.phone_number,
        street=new_addr.street,
        city=new_addr.city,
        state=new_addr.state,
        zipCode=new_addr.zip_code,
        isDefault=new_addr.is_default
    )

# 🔒 Select Address as Default / Active in Cart (Protected)
@router.put("/addresses/{addr_id}/select")
def select_address(
    addr_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    addr = db.query(Address).filter(Address.id == addr_id, Address.user_id == user.id).first()
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")

    # Mark all user addresses as non-default, and this one as default
    db.query(Address).filter(Address.user_id == user.id).update({"is_default": False})
    addr.is_default = True
    db.commit()

    # Update active cart details
    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if not cart:
        cart = Cart(user_id=user.id)
        db.add(cart)
    cart.delivery_address = f"{addr.street}, {addr.city}, {addr.state} {addr.zip_code}"
    cart.recipient_name = addr.recipient_name
    db.commit()

    return {"message": "Address selected successfully"}

# 🔒 Edit Address (Protected)
@router.put("/addresses/{addr_id}", response_model=AddressResponse)
def edit_address(
    data: AddressCreate,
    addr_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    addr = db.query(Address).filter(Address.id == addr_id, Address.user_id == user.id).first()
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")

    if data.isDefault:
        db.query(Address).filter(Address.user_id == user.id).update({"is_default": False})

    addr.label = data.label
    addr.recipient_name = data.recipientName
    addr.phone_number = data.phoneNumber
    addr.street = data.street
    addr.city = data.city
    addr.state = data.state
    addr.zip_code = data.zipCode
    addr.is_default = data.isDefault
    db.commit()
    db.refresh(addr)

    # Also automatically update the active cart with this address if it's default or matches current cart address
    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if not cart:
        cart = Cart(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    
    if data.isDefault or cart.recipient_name == addr.recipient_name:
        cart.delivery_address = f"{addr.street}, {addr.city}, {addr.state} {addr.zip_code}"
        cart.recipient_name = addr.recipient_name
        db.commit()

    return AddressResponse(
        id=str(addr.id),
        label=addr.label,
        recipientName=addr.recipient_name,
        phoneNumber=addr.phone_number,
        street=addr.street,
        city=addr.city,
        state=addr.state,
        zipCode=addr.zip_code,
        isDefault=addr.is_default
    )

# 🔒 Delete Address (Protected)
@router.delete("/addresses/{addr_id}")
def delete_address(
    addr_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    addr = db.query(Address).filter(Address.id == addr_id, Address.user_id == user.id).first()
    if not addr:
        raise HTTPException(status_code=404, detail="Address not found")

    db.delete(addr)
    db.commit()
    return {"message": "Address deleted successfully"}
