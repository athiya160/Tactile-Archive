"""
Seed script – adds realistic books with complete dynamic metadata to the database.
Reflects the authentic 'The Tactile Archive' literary ecosystem and stitch designs.
"""
import sys
import os

# Add parent directory to sys.path so app modules import cleanly
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Import all models to satisfy SQLAlchemy relationships
from app.models.user import User
from app.models.book import Book, BookImage
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.address import Address
from app.models.notification import Notification, FCMToken
from app.models.review import Review
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile
from app.models.badge import Badge, UserBadge
from app.models.subscription import NeighborhoodSubscription
from app.models.password_reset import PasswordReset
from app.models.payment import Payment
from app.models.otp_code import OTPCode

from app.core.database import SessionLocal, engine, Base

BOOKS = [
    # 1. Window into Dawn (Donate / Free) - Featured in Community Catalog
    (
        "Window into Dawn",
        "Sarah Penrose",
        "A luminous collection of essays and reflections capturing quiet morning observations, meditative encounters with the natural world, and introspective musings.",
        "Non-fiction",
        0.0,
        "Meridian Publishing",
        "English",
        "9781982137274",
        "/images/window_into_dawn.jpg",
        4.9,
        "1st Edition",
        "228",
        "Good"
    ),
    # 2. Synthesis: The AI Era (For Sale) - Featured in Community Catalog
    (
        "Synthesis: The AI Era",
        "D. Sterling",
        "A rigorous examination of synthetic intelligence, algorithmic culture, and the cognitive evolution of mankind in the modern technological epoch.",
        "Technology",
        18.50,
        "Cyberne Press",
        "English",
        "9780262033848",
        "/images/synthesis_ai_era.jpg",
        4.8,
        "Revised Hardcover",
        "412",
        "Like New"
    ),
    # 3. The Sea of Stars (For Rent) - Featured in Community Catalog
    (
        "The Sea of Stars",
        "Elena Vance",
        "A poetic maritime journey through cosmic cartography and forgotten stellar navigations across the edge of the known universe.",
        "Fiction",
        1.50,
        "Archipelago House",
        "English",
        "9780143127741",
        "/images/sea_of_stars.jpg",
        4.8,
        "1st Edition",
        "312",
        "Very Good"
    ),
    # 4. Crimson Leaves (For Sale) - Featured in Community Catalog
    (
        "Crimson Leaves",
        "Marcus Gray",
        "An evocative anthology chronicling memory, autumnal nostalgia, and human longing woven through lyrical prose.",
        "Fiction",
        12.00,
        "Oak & Ash Press",
        "English",
        "9780062316097",
        "/images/crimson_leaves.jpg",
        4.7,
        "Clothbound Collector",
        "264",
        "Fine"
    ),
    # 5. Calculus & Craft (For Rent) - Featured in Community Catalog
    (
        "Calculus & Craft",
        "Prof. Leo Aris",
        "Bridging pure mathematical analysis with classical engineering, typography, and functional craftsmanship for serious scholars.",
        "Textbooks",
        3.00,
        "Cambridge Academic Texts",
        "English",
        "9780521876543",
        "/images/calculus_and_craft.jpg",
        4.9,
        "Academic 3rd Edition",
        "580",
        "Good"
    ),
    # 6. The Architect of Forgotten Dreams (Staff Pick / Hero Book)
    (
        "The Architect of Forgotten Dreams",
        "Julian Thorne",
        "A sweeping narrative that bridges the gap between historical fact and ethereal fantasy. Perfect for quiet afternoons.",
        "Fiction",
        2.00,
        "The Bodleian Archival Press",
        "English",
        "9780374275631",
        "/images/hero_architect.jpg",
        4.95,
        "Collector’s First Issue",
        "448",
        "Fine"
    ),
    # 7. Whispers of the Ancient Vellum (Staff Pick / Antique Archive)
    (
        "Whispers of the Ancient Vellum",
        "Elias Thorne",
        "A profound exploration into the tactile history of forgotten binding techniques, antique manuscript preservation, and early literary craftsmanship.",
        "Rare Finds",
        2.50,
        "The Oxford Guild",
        "English (Old Variant)",
        "9780198813456",
        "/images/whispers_ancient_vellum.jpg",
        4.9,
        "1st / 1924",
        "342 Heavy Stock",
        "Collector"
    ),
    # 8. The Shadow of the Wind
    (
        "The Shadow of the Wind",
        "Carlos Ruiz Zafón",
        "Set in post-war Barcelona's Cemetery of Forgotten Books, this gothic mystery echoes with romance, rare manuscripts, and haunting intrigue.",
        "Fiction",
        4.50,
        "Penguin Books",
        "English",
        "9780143034902",
        "/images/shadow_of_wind.jpg",
        4.8,
        "Special Illustrated Edition",
        "487",
        "Very Good"
    ),
    # 9. The Great Gatsby
    (
        "The Great Gatsby",
        "F. Scott Fitzgerald",
        "A portrait of the Jazz Age in all its decadence and excess, Gatsby explores the disillusionment of the American Dream.",
        "Fiction",
        9.99,
        "Scribner",
        "English",
        "9780743273565",
        "/images/the_great_gatsby.jpg",
        4.8,
        "Scribner Classic",
        "180",
        "Good"
    ),
    # 10. Stoner
    (
        "Stoner",
        "John Williams",
        "A quiet, unheralded life rendered with utter perfection. The story of an unassuming Midwestern academic and his devotion to literature.",
        "Fiction",
        2.20,
        "New York Review Books",
        "English",
        "9781590171998",
        "/images/stoner.jpg",
        4.7,
        "NYRB Classics",
        "288",
        "Very Good"
    ),
    # 11. Circe
    (
        "Circe",
        "Madeline Miller",
        "In the house of Helios, god of the sun and mightiest of the Titans, a daughter is born who finds herself possessing the craft of witchcraft.",
        "Fiction",
        14.50,
        "Little, Brown and Company",
        "English",
        "9780316556347",
        "/images/circe.jpg",
        4.9,
        "1st Edition",
        "393",
        "Like New"
    ),
    # 12. Kafka on the Shore
    (
        "Kafka on the Shore",
        "Haruki Murakami",
        "A tour de force of metaphysical reality comprising two remarkable characters: a teenage runaway and an aging simpleton who can talk to cats.",
        "Fiction",
        3.50,
        "Vintage",
        "English",
        "9781400079278",
        "/images/kafka_on_the_shore.jpg",
        4.8,
        "Vintage International",
        "467",
        "Good"
    ),
    # 13. The Goldfinch
    (
        "The Goldfinch",
        "Donna Tartt",
        "Theo Decker, a thirteen-year-old New Yorker, miraculously survives an accident that kills his mother, leading him into the shadowy world of antique art.",
        "Fiction",
        16.00,
        "Little, Brown",
        "English",
        "9780316055437",
        "/images/the_goldfinch.jpg",
        4.7,
        "Hardcover 1st Edition",
        "771",
        "Very Good"
    ),
    # 14. The Alchemist
    (
        "The Alchemist",
        "Paulo Coelho",
        "The mystical story of Santiago, an Andalusian shepherd boy who yearns to travel in search of a worldly treasure.",
        "Fiction",
        1.80,
        "HarperOne",
        "English",
        "9780062315007",
        "/images/the_alchemist.jpg",
        4.8,
        "25th Anniversary Edition",
        "197",
        "Good"
    ),
    # 15. A Moveable Feast
    (
        "A Moveable Feast",
        "Ernest Hemingway",
        "Hemingway’s classic memoir of Paris in the 1920s, capturing the golden age of American expatriate writers with tenderness and vigor.",
        "Non-fiction",
        2.00,
        "Scribner",
        "English",
        "9781439182710",
        "/images/a_moveable_feast.jpg",
        4.6,
        "Restored Edition",
        "240",
        "Good"
    ),
    # 16. Notes from Underground
    (
        "Notes from Underground",
        "Fyodor Dostoevsky",
        "A devastating self-portrait of an alienated, bitter former civil servant living in St. Petersburg, pioneering existential literature.",
        "Fiction",
        10.50,
        "Vintage",
        "English",
        "9780679734529",
        "/images/notes_from_underground.jpg",
        4.7,
        "Vintage Classics",
        "160",
        "Good"
    ),
    # 17. The Waste Land (Donate / Free)
    (
        "The Waste Land",
        "T.S. Eliot",
        "One of the most important 20th-century poems, expressing the disillusionment and psychic fracture of the post-WWI generation.",
        "Poetry",
        0.0,
        "Faber & Faber",
        "English",
        "9780571057061",
        "/images/book1.jpg",
        4.9,
        "Faber 1st Edition",
        "64",
        "Fine"
    ),
    # 18. The Philosophy of Silence
    (
        "The Philosophy of Silence",
        "Archival Curators",
        "A rare treatise meditating on stillness, contemplation, monastic traditions, and the lost craft of quiet concentration.",
        "Philosophy",
        42.00,
        "The Tactile Archive",
        "English",
        "9780198819999",
        "/images/philosophy_of_silence.jpg",
        4.8,
        "Archive Folio",
        "310",
        "Collector"
    ),
    # 19. Ephemeral Architecture
    (
        "Ephemeral Architecture",
        "Studio Nocturne",
        "A photographic and analytical study of temporary pavilions, nomadic structures, and transient spatial installations.",
        "Textbooks",
        8.50,
        "Form & Space",
        "English",
        "9783775744881",
        "/images/ephemeral_architecture.jpg",
        4.5,
        "Monograph Series",
        "280",
        "Like New"
    ),
    # 20. Meditations
    (
        "Meditations",
        "Marcus Aurelius",
        "Personal reflections by the Roman Emperor Marcus Aurelius offering timeless Stoic wisdom on duty, resilience, and inner tranquility.",
        "Philosophy",
        24.00,
        "Modern Library",
        "English",
        "9780812968255",
        "/images/meditations.jpg",
        4.9,
        "Modern Library Edition",
        "254",
        "Fine"
    ),
]

def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Ensure at least one provider user exists
        owner = db.query(User).first()
        if not owner:
            from app.api.auth import hash_password
            owner = User(
                email="athiya160@gmail.com", 
                password=hash_password("password123"), 
                name="Athiya", 
                role="provider",
                is_verified=True,
                onboarding_completed=True
            )
            db.add(owner)
            db.commit()
            db.refresh(owner)
            print("Created provider user: athiya160@gmail.com")

        added = 0
        updated = 0
        for item in BOOKS:
            title, author, desc, cat, price, pub, lang, isbn, cover, rating, edition, pages, condition = item
            existing = db.query(Book).filter(Book.title == title).first()
            if not existing:
                b = Book(
                    title=title, 
                    author=author, 
                    description=desc, 
                    category=cat, 
                    price=price, 
                    publisher=pub,
                    language=lang,
                    isbn=isbn,
                    cover_url=cover,
                    rating=rating,
                    edition=edition,
                    pages=pages,
                    condition=condition,
                    approval_status="approved",
                    condition_verification="verified",
                    owner_id=owner.id
                )
                db.add(b)
                added += 1
            else:
                existing.author = author
                existing.description = desc
                existing.category = cat
                existing.price = price
                existing.publisher = pub
                existing.language = lang
                existing.isbn = isbn
                existing.cover_url = cover
                existing.rating = rating
                existing.edition = edition
                existing.pages = pages
                existing.condition = condition
                existing.approval_status = "approved"
                existing.condition_verification = "verified"
                updated += 1

        db.commit()
        total = db.query(Book).count()
        print(f"OK: Seeded {added} new books, updated {updated} existing books. Total books in DB: {total}")
    finally:
        db.close()

if __name__ == "__main__":
    seed()
