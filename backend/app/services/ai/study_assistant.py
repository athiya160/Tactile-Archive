import json
from app.services.ai.groq_client import groq_client
from app.services.ai.prompt_service import PromptService
from app.models.user import User

class StudyAssistantService:
    @classmethod
    def generate_study_advice(cls, user: User, query: str) -> dict:
        """Generates AI-powered study advice for Student persona."""
        sp = user.student_profile
        subjects = json.loads(sp.subjects) if sp and sp.subjects else []
        student_info = {
            "education_level": sp.education_level if sp else "Undergraduate",
            "course": sp.course if sp else "General",
            "subjects": subjects,
            "exam_goal": sp.exam_goal if sp else "Semester Exams",
            "study_duration": sp.study_duration if sp else 60,
        }

        system_prompt = PromptService.STUDENT_SYSTEM_PROMPT
        user_prompt = PromptService.get_study_assistant_prompt(student_info, query)

        response_text = groq_client.chat_completion(system_prompt, user_prompt, temperature=0.7)

        return {
            "query": query,
            "student_profile": student_info,
            "ai_response": response_text,
            "engine": "groq" if groq_client.is_configured() else "local_fallback",
        }
