import json
from app.services.ai.groq_client import groq_client
from app.services.ai.prompt_service import PromptService
from app.models.user import User

class ReadingCompanionService:
    @classmethod
    def generate_literary_insight(cls, user: User, query: str) -> dict:
        """Generates AI-powered literary insights for Reader persona."""
        rp = user.reader_profile
        genres = json.loads(rp.genres) if rp and rp.genres else []
        authors = json.loads(rp.favorite_authors) if rp and rp.favorite_authors else []

        reader_info = {
            "genres": genres,
            "favorite_authors": authors,
            "reading_goal": rp.reading_goal if rp else "Read 12 books this year",
            "preferred_duration": rp.preferred_duration if rp else 30,
        }

        system_prompt = PromptService.READER_SYSTEM_PROMPT
        user_prompt = PromptService.get_reading_companion_prompt(reader_info, query)

        response_text = groq_client.chat_completion(system_prompt, user_prompt, temperature=0.7)

        return {
            "query": query,
            "reader_profile": reader_info,
            "ai_response": response_text,
            "engine": "groq" if groq_client.is_configured() else "local_fallback",
        }
