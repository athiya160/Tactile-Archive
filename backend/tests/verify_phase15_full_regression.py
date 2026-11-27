import os
import sys
import unittest
from unittest.mock import MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["ENV"] = "development"

from starlette.requests import Request
from fastapi import HTTPException
from app.core.database import SessionLocal
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.api.auth import register, update_user_experience, activate_provider_mode, limiter
from app.api.profile import get_user_composite_profile
from app.api.provider import get_provider_dashboard, require_provider
from app.schemas.user import UserCreate, ExperienceUpdatePayload, ProviderActivationPayload

limiter.enabled = False

def create_request(method="GET", path="/"):
    scope = {
        "type": "http",
        "method": method,
        "path": path,
        "headers": [(b"host", b"localhost:8000")],
        "client": ("127.0.0.1", 12345),
    }
    return Request(scope)

class TestPhase15FullRegression(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_01_student_flow(self):
        req = create_request(method="POST", path="/register")
        bg = MagicMock()
        email = "student_full_test_2026@tactile.archive"
        self.db.query(StudentProfile).filter(StudentProfile.user_id.in_(
            self.db.query(User.id).filter(User.email == email)
        )).delete(synchronize_session=False)
        self.db.query(User).filter(User.email == email).delete()
        self.db.commit()

        student_payload = UserCreate(
            name="Alice Academic",
            email=email,
            phone="+919876500001",
            password="StrongPassword123!",
            user_type="student",
            active_experience="student",
            college="Indian Institute of Science",
            course="M.Tech Computer Science",
            semester="Semester 3",
            graduation_year="2027",
            syllabus_details="Advanced Operating Systems, Distributed Systems",
            accept_terms=True
        )

        res = register(req, student_payload, bg, self.db)
        self.assertEqual(res["user_type"], "student")
        self.assertEqual(res["active_experience"], "student")
        self.assertFalse(res["provider_enabled"])
        self.assertEqual(res["provider_status"], "not_enrolled")

        user = self.db.query(User).filter(User.email == email).first()
        self.assertIsNotNone(user)
        self.assertIsNotNone(user.student_profile)
        self.assertEqual(user.student_profile.college, "Indian Institute of Science")
        self.assertEqual(user.student_profile.course, "M.Tech Computer Science")
        self.assertEqual(user.student_profile.semester, "Semester 3")

    def test_02_reader_flow_and_experience_switching(self):
        req = create_request(method="POST", path="/register")
        bg = MagicMock()
        email = "reader_full_test_2026@tactile.archive"
        self.db.query(User).filter(User.email == email).delete()
        self.db.commit()

        reader_payload = UserCreate(
            name="Bob Bookworm",
            email=email,
            phone="+919876500002",
            password="StrongPassword123!",
            user_type="reader",
            active_experience="reader",
            accept_terms=True
        )

        res = register(req, reader_payload, bg, self.db)
        self.assertEqual(res["user_type"], "reader")
        self.assertEqual(res["active_experience"], "reader")
        self.assertFalse(res["provider_enabled"])

        user = self.db.query(User).filter(User.email == email).first()
        self.assertIsNone(user.student_profile)

        # Composite Profile API
        profile = get_user_composite_profile(user=user, db=self.db)
        self.assertEqual(profile["active_experience"], "reader")
        self.assertFalse(profile["provider_enabled"])

        # Switch to student experience
        switch_res = update_user_experience(
            payload=ExperienceUpdatePayload(active_experience="student"),
            user=user
        )
        self.assertEqual(switch_res["active_experience"], "student")
        self.assertEqual(user.active_experience, "student")

        # Switch back to reader experience
        switch_back = update_user_experience(
            payload=ExperienceUpdatePayload(active_experience="reader"),
            user=user
        )
        self.assertEqual(switch_back["active_experience"], "reader")
        self.assertEqual(user.active_experience, "reader")

    def test_03_provider_activation_and_security(self):
        email = "reader_full_test_2026@tactile.archive"
        user = self.db.query(User).filter(User.email == email).first()
        self.assertIsNotNone(user)

        # Before activation: provider endpoints must reject non-providers
        with self.assertRaises(HTTPException) as cm:
            require_provider(user=user)
        self.assertEqual(cm.exception.status_code, 403)
        self.assertIn("Provider mode must be activated", cm.exception.detail)

        # Activate provider mode
        act_res = activate_provider_mode(
            payload=ProviderActivationPayload(
                business_name="Bob's Cozy Archive Corner",
                phone="+919876500002"
            ),
            user=user
        )
        self.assertTrue(act_res["provider_enabled"])
        self.assertEqual(act_res["provider_status"], "active")

        # After activation: require_provider succeeds
        verified_user = require_provider(user=user)
        self.assertEqual(verified_user.id, user.id)
        self.assertTrue(verified_user.provider_enabled)

        # Access dashboard
        dash = get_provider_dashboard(user=user, db=self.db)
        self.assertIn("metrics", dash)
        self.assertIn("total_listings", dash["metrics"])
        self.assertIn("action_required", dash)

if __name__ == "__main__":
    suite = unittest.TestLoader().loadTestsFromTestCase(TestPhase15FullRegression)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    if result.wasSuccessful():
        print("\nALL PHASE 15 FULL REGRESSION TESTS PASSED (3/3)!")
        sys.exit(0)
    else:
        print("\nTESTS FAILED!")
        sys.exit(1)
