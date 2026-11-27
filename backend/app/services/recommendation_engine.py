import json
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.book import Book
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile

class RecommendationEngine:
    @staticmethod
    def _parse_json_list(val) -> List[str]:
        if not val:
            return []
        try:
            res = json.loads(val)
            return [str(item).strip().lower() for item in res if item]
        except Exception:
            return []

    @classmethod
    def get_recommendations_for_user(cls, user: User, db: Session, limit: int = 10) -> List[Dict[str, Any]]:
        """Determines persona type and returns ranked recommendations."""
        if user.user_type == "student":
            return cls.recommend_for_student(user, db, limit)
        else:
            return cls.recommend_for_reader(user, db, limit)

    @classmethod
    def recommend_for_student(cls, user: User, db: Session, limit: int = 10) -> List[Dict[str, Any]]:
        """Candidate generation and weighted scoring for Student persona."""
        sp = user.student_profile
        subjects = cls._parse_json_list(sp.subjects) if sp else []
        course = (sp.course or "").lower() if sp else ""
        education_level = (sp.education_level or "").lower() if sp else ""

        # Fetch candidate books
        all_books = db.query(Book).all()
        scored_books = []

        for book in all_books:
            score = 0.0
            matched_reasons = []

            title_lower = (book.title or "").lower()
            desc_lower = (book.description or "").lower()
            cat_lower = (book.category or "").lower()
            author_lower = (book.author or "").lower()

            # 1. Subject matching (+3.0 points per matching subject)
            for subj in subjects:
                if subj in title_lower or subj in desc_lower or subj in cat_lower:
                    score += 3.0
                    if f"Subject: {subj.title()}" not in matched_reasons:
                        matched_reasons.append(f"Subject: {subj.title()}")

            # 2. Course / Education level matching (+2.0 points)
            if course and (course in cat_lower or course in title_lower or course in desc_lower):
                score += 2.0
                matched_reasons.append(f"Course: {sp.course}")

            if education_level and (education_level in cat_lower or education_level in desc_lower):
                score += 1.5
                matched_reasons.append(f"Level: {sp.education_level}")

            # 3. Base rating boost (+0.5 * rating)
            score += float(book.rating or 4.0) * 0.5

            # Default fallback match reason if score has base boost only
            if not matched_reasons:
                matched_reasons.append("Popular Academic Catalog")

            scored_books.append({
                "book": book,
                "score": score,
                "match_reasons": matched_reasons,
            })

        # Rank candidates by score descending
        scored_books.sort(key=lambda x: x["score"], reverse=True)
        top_candidates = scored_books[:limit]

        # Format output
        results = []
        for item in top_candidates:
            b = item["book"]
            price_val = float(b.price or 0.0)
            rental_val = round(price_val * 0.25, 2) if price_val > 0 else 0.0
            cover = getattr(b, "image_url", b.cover_url or "")
            results.append({
                "id": b.id,
                "title": b.title,
                "author": b.author,
                "category": b.category or "Academic & Textbooks",
                "price": price_val,
                "rental_price": rental_val,
                "image": cover,
                "image_url": cover,
                "cover_url": cover,
                "rating": float(b.rating or 4.5),
                "available": (b.stock if b.stock is not None else 1) > 0,
                "match_score": round(item["score"], 2),
                "match_reasons": item["match_reasons"],
            })

        return results

    @classmethod
    def recommend_for_reader(cls, user: User, db: Session, limit: int = 10) -> List[Dict[str, Any]]:
        """Candidate generation and weighted scoring for Reader persona."""
        rp = user.reader_profile
        genres = cls._parse_json_list(rp.genres) if rp else []
        favorite_authors = cls._parse_json_list(rp.favorite_authors) if rp else []

        all_books = db.query(Book).all()
        scored_books = []

        for book in all_books:
            score = 0.0
            matched_reasons = []

            title_lower = (book.title or "").lower()
            desc_lower = (book.description or "").lower()
            cat_lower = (book.category or "").lower()
            author_lower = (book.author or "").lower()

            # 1. Favorite Author matching (+4.0 points)
            for author in favorite_authors:
                if author and (author in author_lower or author_lower in author):
                    score += 4.0
                    matched_reasons.append(f"Author: {book.author}")

            # 2. Favorite Genre matching (+2.5 points per matching genre)
            for genre in genres:
                if genre and (genre in cat_lower or genre in title_lower or genre in desc_lower):
                    score += 2.5
                    if f"Genre: {genre.title()}" not in matched_reasons:
                        matched_reasons.append(f"Genre: {genre.title()}")

            # 3. Base rating boost (+0.5 * rating)
            score += float(book.rating or 4.0) * 0.5

            if not matched_reasons:
                matched_reasons.append("Trending Community Shelf")

            scored_books.append({
                "book": book,
                "score": score,
                "match_reasons": matched_reasons,
            })

        # Rank candidates by score descending
        scored_books.sort(key=lambda x: x["score"], reverse=True)
        top_candidates = scored_books[:limit]

        results = []
        for item in top_candidates:
            b = item["book"]
            price_val = float(b.price or 0.0)
            rental_val = round(price_val * 0.25, 2) if price_val > 0 else 0.0
            cover = getattr(b, "image_url", b.cover_url or "")
            results.append({
                "id": b.id,
                "title": b.title,
                "author": b.author,
                "category": b.category or "Literary Catalog",
                "price": price_val,
                "rental_price": rental_val,
                "image": cover,
                "image_url": cover,
                "cover_url": cover,
                "rating": float(b.rating or 4.5),
                "available": (b.stock if b.stock is not None else 1) > 0,
                "match_score": round(item["score"], 2),
                "match_reasons": item["match_reasons"],
            })

        return results
