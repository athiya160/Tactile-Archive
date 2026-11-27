from passlib.context import CryptContext

pc = CryptContext(schemes=["bcrypt"])
h = "$2b$12$/0WbX1klTmCs1Py1Uq.w8evHdbQR0kNA8kffEEuJldfcEBGFQP5nK"

print("password:", pc.verify("password", h))
