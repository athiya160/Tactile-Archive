from app.services.ai.groq_client import groq_client
from app.services.ai.prompt_service import PromptService
from app.models.user import User

class RecommendationExplainerService:
    @classmethod
    def explain_recommendation(cls, user: User, book_info: dict) -> dict:
        """Explains why a candidate book was recommended using Groq LLM."""
        user_profile = {
            "user_type": user.user_type,
            "details": {
                "course": user.student_profile.course if user.student_profile else None,
                "genres": user.reader_profile.genres if user.reader_profile else None,
            }
        }

        system_prompt = PromptService.EXPLAINER_SYSTEM_PROMPT
        user_prompt = PromptService.get_explainer_prompt(book_info, user_profile)

        explanation = groq_client.chat_completion(system_prompt, user_prompt, temperature=0.5)

        return {
            "book_id": book_info.get("id"),
            "title": book_info.get("title"),
            "explanation": explanation,
            "engine": "groq" if groq_client.is_configured() else "local_fallback",
        }
