import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
import json
from unittest.mock import MagicMock
from fastapi import HTTPException
from starlette.requests import Request
from app.core.rate_limit import limiter
from app.core.database import SessionLocal
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.schemas.user import UserCreate, ExperienceUpdatePayload, ProviderActivationPayload
from app.schemas.student_profile import StudentProfilePayload
from app.api.auth import register, login, update_user_experience, activate_provider_mode, hash_password
from app.api.profile import get_user_composite_profile, update_student_profile
from app.api.provider import get_provider_dashboard, require_provider
from app.api.admin import require_admin

def test_adaptive_experience_lifecycle():
    limiter.enabled = False
    db = SessionLocal()
    try:
        # Clean up any leftover test users
        for email in ["test_student_adaptive@example.com", "test_reader_adaptive@example.com"]:
            u = db.query(User).filter(User.email == email).first()
            if u:
                db.delete(u)
                db.commit()

        scope = {
            "type": "http",
            "method": "POST",
            "path": "/register",
            "headers": [(b"host", b"localhost:8000")],
            "client": ("127.0.0.1", 12345),
        }
        dummy_req = Request(scope)
        dummy_bg = MagicMock()

        # ─── 1. STUDENT REGISTRATION ───
        student_create = UserCreate(
            name="Sarah Student",
            email="test_student_adaptive@example.com",
            password="StrongStudentPass123!",
            user_type="student",
            active_experience="student",
            college="Oxford Technical Institute",
            course="Computer Engineering",
            semester="Semester 5",
            graduation_year="2027"
        )
        reg_res = register(dummy_req, student_create, dummy_bg, db)
        assert reg_res["user_type"] == "student"
        assert reg_res["active_experience"] == "student"
        assert reg_res["provider_enabled"] is False
        assert reg_res["onboarding_completed"] is True

        # Verify StudentProfile was automatically initialized in database
        student_user = db.query(User).filter(User.email == "test_student_adaptive@example.com").first()
        assert student_user is not None
        assert student_user.student_profile is not None
        assert student_user.student_profile.course == "Computer Engineering"
        assert student_user.student_profile.college == "Oxford Technical Institute"
        assert student_user.student_profile.semester == "Semester 5"

        # ─── 2. READER REGISTRATION ───
        reader_create = UserCreate(
            name="Rachel Reader",
            email="test_reader_adaptive@example.com",
            password="StrongReaderPass123!",
            user_type="reader",
            active_experience="reader"
        )
        r_res = register(dummy_req, reader_create, dummy_bg, db)
        assert r_res["user_type"] == "reader"
        assert r_res["active_experience"] == "reader"
        assert r_res["provider_enabled"] is False

        reader_user = db.query(User).filter(User.email == "test_reader_adaptive@example.com").first()
        assert reader_user is not None
        assert reader_user.student_profile is None  # Reader must NOT have student profile automatically created

        # ─── 3. DASHBOARD COMPOSITE PROFILES ───
        student_comp = get_user_composite_profile(user=student_user, db=db)
        assert student_comp["active_experience"] == "student"
        assert student_comp["student_profile"] is not None
        assert student_comp["student_profile"]["college"] == "Oxford Technical Institute"

        reader_comp = get_user_composite_profile(user=reader_user, db=db)
        assert reader_comp["active_experience"] == "reader"
        assert reader_comp["student_profile"] is None

        # ─── 4. EXPERIENCE SWITCHING (Reader -> Student -> Reader) ───
        # Reader switches to student experience
        switch_to_student = update_user_experience(
            payload=ExperienceUpdatePayload(active_experience="student"),
            user=reader_user
        )
        assert switch_to_student["active_experience"] == "student"
        assert reader_user.active_experience == "student"

        # Switch back to reader
        switch_to_reader = update_user_experience(
            payload=ExperienceUpdatePayload(active_experience="reader"),
            user=reader_user
        )
        assert switch_to_reader["active_experience"] == "reader"
        assert reader_user.active_experience == "reader"

        # Invalid experience fails with 400
        with pytest.raises(HTTPException) as exc_info:
            update_user_experience(
                payload=ExperienceUpdatePayload(active_experience="hacker_mode"),
                user=reader_user
            )
        assert exc_info.value.status_code == 400

        # ─── 5. PROVIDER SECURITY & ACTIVATION ───
        # Non-provider attempting provider access must be rejected with 403 Forbidden
        assert reader_user.provider_enabled is False
        with pytest.raises(HTTPException) as exc_info:
            require_provider(user=reader_user)
        assert exc_info.value.status_code == 403
        assert "Provider mode must be activated" in exc_info.value.detail

        # Now reader activates provider functionality
        act_res = activate_provider_mode(
            payload=ProviderActivationPayload(phone="9876543210", address="124 Archive Lane"),
            user=reader_user
        )
        assert act_res["provider_enabled"] is True
        assert act_res["provider_status"] == "active"
        assert reader_user.provider_enabled is True

        # Now require_provider succeeds!
        prov_user = require_provider(user=reader_user)
        assert prov_user.id == reader_user.id

        # Reader accesses Provider Dashboard successfully
        dash = get_provider_dashboard(db=db, user=reader_user)
        assert "metrics" in dash
        assert dash["metrics"]["total_listings"] == 0

        # Student also activates provider functionality without creating second account
        student_act = activate_provider_mode(
            payload=ProviderActivationPayload(phone="9988776655"),
            user=student_user
        )
        assert student_act["provider_enabled"] is True
        assert student_user.provider_enabled is True
        # Student preserves student profile!
        assert student_user.student_profile.course == "Computer Engineering"

        # ─── 6. ADMIN AUTHORIZATION SECURITY ───
        # Normal user cannot access admin
        with pytest.raises(HTTPException) as exc_info:
            require_admin(user=reader_user)
        assert exc_info.value.status_code == 403

        # Admin user succeeds
        admin_user = User(email="super_admin@example.com", is_admin=True)
        assert require_admin(user=admin_user).email == "super_admin@example.com"

        print("\nALL ADAPTIVE EXPERIENCE & SECURITY TESTS PASSED PERFECTLY!")

    finally:
        # Clean up test users
        for email in ["test_student_adaptive@example.com", "test_reader_adaptive@example.com"]:
            u = db.query(User).filter(User.email == email).first()
            if u:
                db.delete(u)
                db.commit()
        db.close()

if __name__ == "__main__":
    test_adaptive_experience_lifecycle()
