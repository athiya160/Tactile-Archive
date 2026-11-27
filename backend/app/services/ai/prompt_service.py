import json

class PromptService:
    """Centralized prompt templates for Student and Reader AI workflows."""

    STUDENT_SYSTEM_PROMPT = """
You are the AI Study Assistant for 'The Tactile Archive' peer-to-peer academic library.
Your goal is to provide concise, structured academic study advice, exam preparation schedules, 
and textbook reading strategies tailored to the student's degree program, active subjects, and exam goals.
Be encouraging, precise, and academically rigorous.
"""

    READER_SYSTEM_PROMPT = """
You are the AI Reading Companion for 'The Tactile Archive' literary ecosystem.
Your goal is to provide thoughtful literary commentary, genre insights, reading goal advice, 
and bookshelf curation recommendations tailored to the reader's favorite genres and authors.
Be warm, articulate, and deeply passionate about literature.
"""

    EXPLAINER_SYSTEM_PROMPT = """
You are the Recommendation Explainer for 'The Tactile Archive'.
Your task is to explain why a specific book was recommended to the user in 2 concise sentences, 
connecting the book's themes/subjects directly to the user's explicit profile preferences.
"""

    @classmethod
    def get_study_assistant_prompt(cls, student_info: dict, user_query: str) -> str:
        return f"""
Student Profile Context:
- Education Level: {student_info.get('education_level', 'Undergraduate')}
- Degree / Course: {student_info.get('course', 'General')}
- Active Subjects: {', '.join(student_info.get('subjects', []))}
- Exam Goal: {student_info.get('exam_goal', 'Semester Exams')}
- Target Study Duration: {student_info.get('study_duration', 60)} minutes/day

Student Request: "{user_query}"
Provide a clear, actionable study breakdown or explanation.
"""

    @classmethod
    def get_reading_companion_prompt(cls, reader_info: dict, user_query: str) -> str:
        return f"""
Reader Profile Context:
- Favorite Genres: {', '.join(reader_info.get('genres', []))}
- Favorite Authors: {', '.join(reader_info.get('favorite_authors', []))}
- Annual Reading Goal: {reader_info.get('reading_goal', 'Read 12 books this year')}
- Target Daily Reading: {reader_info.get('preferred_duration', 30)} minutes/day

Reader Request: "{user_query}"
Provide engaging, insightful literary commentary or recommendation guidance.
"""

    @classmethod
    def get_explainer_prompt(cls, book_info: dict, user_profile: dict) -> str:
        return f"""
Book Title: "{book_info.get('title')}" by {book_info.get('author')}
Category: {book_info.get('category')}
Match Reasons: {', '.join(book_info.get('match_reasons', []))}

User Persona: {user_profile.get('user_type')}
User Preferences: {json.dumps(user_profile.get('details', {}))}

Explain why this book is a great match in 2 sentences.
"""
