import sys
from fastapi.testclient import TestClient
from app.main import app

def test_flow():
    client = TestClient(app)
    
    # 1. Signup
    print("1. Testing Signup...")
    import random
    email = f"test_user_{random.randint(1000, 9999)}@example.com"
    password = "password123"
    name = "E2E Tester"
    
    res = client.post("/register", json={
        "email": email,
        "password": password,
        "name": name,
        "role": "provider"
    })
    print("Signup status:", res.status_code)
    if res.status_code in [200, 201]:
        data = res.json()
        print("Registered successfully. Token exists:", "access_token" in data)
    elif res.status_code == 400 and "already registered" in res.text:
        print("User already registered, proceeding to login.")
    else:
        assert False, f"Signup failed: {res.text}"

    # 2. Login
    print("\n2. Testing Login...")
    res = client.post("/login", json={
        "email": email,
        "password": password
    })
    assert res.status_code == 200, f"Login failed: {res.text}"
    
    data = res.json()
    token = data.get("access_token")
    assert token is not None
    
    for field in ["id", "email", "full_name", "role", "access_token"]:
        assert field in data, f"Required field '{field}' is missing from login response"
        
    assert data["role"] == "provider", f"Expected role 'provider', got '{data['role']}'"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 3. Get profile
    print("\n3. Testing Profile flow...")
    res = client.get("/profile", headers=headers)
    assert res.status_code == 200, f"Profile fetch failed: {res.text}"

    # 4. Get books catalog
    print("\n4. Testing Book Listing...")
    res = client.get("/books", headers=headers)
    assert res.status_code == 200, f"Book listing failed: {res.text}"
    books_data = res.json()
    books_list = books_data.get("data", [])
    assert len(books_list) > 0, "No books found in catalog"
    book_id = books_list[0]["id"]

    # 5. Book Details
    print("\n5. Testing Book Details...")
    res = client.get(f"/books/{book_id}", headers=headers)
    assert res.status_code == 200, f"Book details failed: {res.text}"

    # 6. Add to Cart
    print("\n6. Testing Add To Cart...")
    res = client.post("/cart/items", headers=headers, json={
        "bookId": int(book_id),
        "isPurchase": True
    })
    assert res.status_code in [200, 201], f"Add to cart failed: {res.text}"

    # 6b. Add same book again (should increment quantity)
    res = client.post("/cart/items", headers=headers, json={
        "bookId": int(book_id),
        "isPurchase": True
    })
    assert res.status_code in [200, 201]

    # 7. Cart Retrieval
    res = client.get("/cart", headers=headers)
    assert res.status_code == 200
    cart_data = res.json()
    items = cart_data.get("items", [])
    assert len(items) > 0
    item_id = items[0]["id"]
    assert items[0]["quantity"] == 2

    # 7b. Update quantity via PUT to 3
    res = client.put(f"/cart/items/{item_id}", headers=headers, json={"quantity": 3})
    assert res.status_code == 200
    res = client.get("/cart", headers=headers)
    assert res.json()["items"][0]["quantity"] == 3

    # 7c. Update quantity to 0 (remove)
    res = client.put(f"/cart/items/{item_id}", headers=headers, json={"quantity": 0})
    assert res.status_code == 200
    res = client.get("/cart", headers=headers)
    assert len(res.json().get("items", [])) == 0

    # 7d. Re-add item for checkout
    client.post("/cart/items", headers=headers, json={"bookId": int(book_id), "isPurchase": True})

    # 8. Set Delivery Address
    res = client.put("/cart/delivery", headers=headers, json={
        "address": "123 Test Street, Tester City, TS 12345",
        "recipient": "E2E Tester"
    })
    assert res.status_code == 200

    # 9. Checkout
    res = client.post("/orders/checkout", headers=headers, json={
        "payment_method": "UPI",
        "shipping_address": "123 Test Street, Tester City, TS 12345"
    })
    assert res.status_code == 200

    # 10. Orders History
    res = client.get("/orders", headers=headers)
    assert res.status_code == 200
    assert len(res.json()) > 0
