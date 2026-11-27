import json
from app.services.ai.groq_client import groq_client
from app.models.user import User

class PlanGeneratorService:
    @classmethod
    def generate_student_study_plan(cls, user: User, target_goal: str, daily_minutes: int, duration_days: int) -> dict:
        """Generates a structured day-by-day academic study plan."""
        sp = user.student_profile
        subjects = json.loads(sp.subjects) if sp and sp.subjects else ["General Study", "Exam Revision"]
        course = sp.course if sp else "Academic Program"

        system_prompt = "You are an expert Academic Plan Generator for students. Create a realistic, day-by-day study timetable."
        user_prompt = f"""
Student Course: {course}
Goal: {target_goal}
Daily Available Study Time: {daily_minutes} minutes
Plan Duration: {duration_days} days
Active Subjects: {', '.join(subjects)}

Format a clear day-by-day breakdown for Day 1 through Day {min(duration_days, 14)}.
For each day, allocate time blocks across subjects and include a 15-min self-quiz or recap session.
"""

        response_text = groq_client.chat_completion(system_prompt, user_prompt, temperature=0.6)

        return {
            "user_type": "student",
            "course": course,
            "target_goal": target_goal,
            "daily_minutes": daily_minutes,
            "duration_days": duration_days,
            "subjects": subjects,
            "plan_output": response_text,
            "engine": "groq" if groq_client.is_configured() else "local_fallback",
        }

    @classmethod
    def generate_reader_reading_plan(cls, user: User, book_title: str, total_pages: int, daily_minutes: int) -> dict:
        """Generates a structured day-by-day reading plan."""
        rp = user.reader_profile
        goal = rp.reading_goal if rp else "Finish reading"

        # Estimate reading speed: ~1 page per 2 minutes
        pages_per_day = max(5, int((daily_minutes / 2)))
        total_days = max(1, (total_pages + pages_per_day - 1) // pages_per_day)

        system_prompt = "You are a Reading Schedule Coach. Generate an encouraging, page/chapter reading plan."
        user_prompt = f"""
Book Title: "{book_title}"
Total Pages: {total_pages}
Daily Available Reading: {daily_minutes} minutes (~{pages_per_day} pages/day)
Estimated Completion: {total_days} days
Annual Reading Goal: {goal}

Generate a clear day-by-day milestone schedule for Day 1 through Day {min(total_days, 14)}.
Include reflection prompts or chapter goals for each reading block.
"""

        response_text = groq_client.chat_completion(system_prompt, user_prompt, temperature=0.6)

        return {
            "user_type": "reader",
            "book_title": book_title,
            "total_pages": total_pages,
            "daily_minutes": daily_minutes,
            "estimated_days": total_days,
            "plan_output": response_text,
            "engine": "groq" if groq_client.is_configured() else "local_fallback",
        }
