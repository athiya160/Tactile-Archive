from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem
from app.models.user import User
from app.models.book import Book
from app.schemas.cart import CartResponse, CartItemCreate, CartDeliveryUpdate, CartItemUpdate
from app.api.auth import get_current_user

router = APIRouter()

# DB Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_or_create_cart(db: Session, user_id: int) -> Cart:
    cart = db.query(Cart).filter(Cart.user_id == user_id).first()
    if not cart:
        cart = Cart(user_id=user_id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    
    if not cart.delivery_address:
        from app.models.address import Address
        default_addr = db.query(Address).filter(Address.user_id == user_id, Address.is_default == True).first()
        if not default_addr:
            default_addr = db.query(Address).filter(Address.user_id == user_id).first()
        if default_addr:
            cart.delivery_address = f"{default_addr.street}, {default_addr.city}, {default_addr.state} {default_addr.zip_code}"
            cart.recipient_name = default_addr.recipient_name
            db.commit()
            db.refresh(cart)
            
    return cart

def build_cart_response(cart: Cart, db: Session) -> dict:
    items_response = []
    for item in cart.items:
        if not item.book:
            continue
        items_response.append({
            "id": str(item.id),
            "bookId": str(item.book.id),
            "title": item.book.title,
            "author": item.book.author,
            "coverUrl": item.book.image_url,
            "price": item.book.price or 0.0,
            "isPurchase": item.is_purchase,
            "rentalDays": item.rental_days,
            "quantity": item.quantity or 1
        })
    return {
        "items": items_response,
        "deliveryAddress": cart.delivery_address,
        "recipientName": cart.recipient_name,
        "archiveFee": cart.archive_fee,
        "shippingFee": cart.shipping_fee
    }

@router.get("/cart")
def get_cart(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    cart = get_or_create_cart(db, user.id)
    return build_cart_response(cart, db)

@router.get("/cart/items")
def get_cart_items(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    cart = get_or_create_cart(db, user.id)
    return build_cart_response(cart, db)['items']

@router.post("/cart/items/{book_id}")
def add_to_cart_by_id(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    
    # Check if book exists
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    # Check if already in cart
    existing_item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.book_id == book_id
    ).first()
    
    if existing_item:
        existing_item.quantity = (existing_item.quantity or 1) + 1
        db.commit()
        return {"message": "Quantity incremented in cart"}
        
    new_item = CartItem(
        cart_id=cart.id,
        book_id=book_id,
        is_purchase=False, # Default for direct add
        rental_days=14,      # Default
        quantity=1
    )
    db.add(new_item)
    db.commit()
    
    return {"message": "Added to cart"}

@router.post("/cart/items")
def add_to_cart(
    item_data: CartItemCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    
    target_id = item_data.target_book_id
    
    # Check if book exists
    book = db.query(Book).filter(Book.id == target_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    # Check if already in cart
    existing_item = db.query(CartItem).filter(
        CartItem.cart_id == cart.id,
        CartItem.book_id == target_id
    ).first()
    
    add_qty = item_data.quantity if item_data.quantity and item_data.quantity > 0 else 1
    if existing_item:
        existing_item.quantity = (existing_item.quantity or 1) + add_qty
        db.commit()
        return {"message": "Quantity incremented in cart"}
        
    new_item = CartItem(
        cart_id=cart.id,
        book_id=target_id,
        is_purchase=item_data.resolved_is_purchase,
        rental_days=item_data.resolved_rental_days,
        quantity=add_qty
    )
    db.add(new_item)
    db.commit()
    
    return {"message": "Added to cart"}

@router.delete("/cart/items/{item_id}")
def remove_from_cart(
    item_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    item = db.query(CartItem).filter(
        CartItem.id == item_id,
        CartItem.cart_id == cart.id
    ).first()
    
    if not item:
        # Fallback in case frontend sends book_id instead of item_id
        item = db.query(CartItem).filter(
            CartItem.book_id == item_id,
            CartItem.cart_id == cart.id
        ).first()
        if not item:
            raise HTTPException(status_code=404, detail="Item not found in cart")
            
    db.delete(item)
    db.commit()
    return {"message": "Removed from cart"}

@router.put("/cart/items/{item_id}")
def update_cart_item(
    item_id: int,
    data: CartItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    item = db.query(CartItem).filter(
        CartItem.id == item_id,
        CartItem.cart_id == cart.id
    ).first()
    
    if not item:
        # Fallback in case frontend sends book_id instead of item_id
        item = db.query(CartItem).filter(
            CartItem.book_id == item_id,
            CartItem.cart_id == cart.id
        ).first()
        if not item:
            raise HTTPException(status_code=404, detail="Item not found in cart")
            
    if data.quantity <= 0:
        db.delete(item)
        db.commit()
        return {"message": "Item removed from cart"}
        
    item.quantity = data.quantity
    db.commit()
    return {"message": "Cart item quantity updated"}

@router.put("/cart/delivery")
def set_delivery_address(
    data: CartDeliveryUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    cart.delivery_address = data.address
    cart.recipient_name = data.recipient
    db.commit()
    return {"message": "Delivery address updated"}

@router.post("/cart/checkout")
def checkout(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart = get_or_create_cart(db, user.id)
    cart_items = db.query(CartItem).filter(CartItem.cart_id == cart.id).all()
    
    if not cart_items:
        raise HTTPException(status_code=400, detail="Cart is empty")
        
    try:
        total_amount = 0.0
        for item in cart_items:
            book = db.query(Book).filter(Book.id == item.book_id).first()
            if book:
                if item.is_purchase:
                    total_amount += (book.price or 0.0) * item.quantity
                else:
                    days = item.rental_days or 14
                    total_amount += (book.price or 0.0) * 0.15 * (days / 14.0) * item.quantity

        # Create the Order
        new_order = Order(
            user_id=user.id,
            total_items=sum(item.quantity for item in cart_items),
            total_amount=total_amount,
            delivery_address=f"{cart.recipient_name or ''} {cart.delivery_address or ''}".strip(),
            payment_status="completed" # Simplified for this milestone
        )
        db.add(new_order)
        db.flush() # To get the new_order.id
        
        # Create Order Items and Reduce Stock safely
        for item in cart_items:
            # Lock the book row for update to prevent race conditions
            book = db.query(Book).with_for_update().filter(Book.id == item.book_id).first()
            if not book:
                raise HTTPException(status_code=400, detail=f"Book ID {item.book_id} is no longer available.")
            
            # Inventory Validation
            if book.stock < item.quantity:
                raise HTTPException(status_code=400, detail=f"'{book.title}' is out of stock. Only {book.stock} available.")
                
            # Reduce stock
            book.stock -= item.quantity
            
            item_price = 0.0
            if item.is_purchase:
                item_price = book.price or 0.0
            else:
                days = item.rental_days or 14
                item_price = (book.price or 0.0) * 0.15 * (days / 14.0)

            # Add to order
            order_item = OrderItem(
                order_id=new_order.id,
                book_id=book.id,
                book_title=book.title,
                book_author=book.author,
                book_image=book.image_url,
                is_purchase=item.is_purchase,
                rental_days=item.rental_days,
                quantity=item.quantity,
                price=item_price
            )
            db.add(order_item)
                
        # Clear the cart items
        db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
        
        # Reset address
        cart.delivery_address = None
        cart.recipient_name = None
        
        db.commit()
        return {"message": "Checkout successful", "order_id": new_order.id}
    except Exception as e:
        db.rollback()
        raise e
