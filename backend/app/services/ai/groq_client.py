import os
import json
import logging
import urllib.request
import urllib.error

logger = logging.getLogger(__name__)

class GroqClient:
    """Centralized Groq API client securely executing on FastAPI backend."""

    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY", "")
        self.model = os.getenv("GROQ_MODEL", "qwen/qwen3.6-27b")
        self.api_url = "https://api.groq.com/openai/v1/chat/completions"

    def is_configured(self) -> bool:
        key = os.getenv("GROQ_API_KEY", self.api_key)
        return bool(key and key.strip())

    def chat_completion(self, system_prompt: str, user_prompt: str, temperature: float = 0.7) -> str:
        """Executes chat completion request against Groq API with automatic fallback."""
        api_key = os.getenv("GROQ_API_KEY", self.api_key)
        if not api_key or not api_key.strip():
            logger.warning("[GroqClient] GROQ_API_KEY is not configured. Falling back to local intelligence mode.")
            return self._generate_fallback_response(system_prompt, user_prompt)

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": temperature,
            "max_tokens": 1024,
        }

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) LibriFlow/1.0",
        }

        try:
            req = urllib.request.Request(
                self.api_url,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=15) as response:
                if response.status == 200:
                    resp_data = json.loads(response.read().decode("utf-8"))
                    choices = resp_data.get("choices", [])
                    if choices:
                        return choices[0].get("message", {}).get("content", "").strip()
        except urllib.error.HTTPError as e:
            logger.error(f"[GroqClient] HTTP Error {e.code}: {e.read().decode('utf-8')}")
        except Exception as e:
            logger.error(f"[GroqClient] Request error: {str(e)}")

        return self._generate_fallback_response(system_prompt, user_prompt)

    def _generate_fallback_response(self, system_prompt: str, user_prompt: str) -> str:
        """Local fallback response generator when Groq API key is unconfigured or unreachable."""
        q = user_prompt.lower()

        # Check for Student Study Assistant requests
        if "student" in system_prompt.lower() or "study" in q or "explain" in q or "quiz" in q or "flashcard" in q or "prep" in q:
            # Mode: Quiz
            if "quiz" in q:
                if "normalization" in q or "1nf" in q or "2nf" in q or "3nf" in q or "bcnf" in q or "database" in q or "dbms" in q:
                    return (
                        "❓ **Database Normalization Practice Quiz**\n\n"
                        "1. **Question 1: Partial Dependency Elimination**:\n"
                        "   • Which normal form guarantees that no non-prime attribute is functionally dependent on a part of a candidate key?\n"
                        "   • A) 1NF   B) 2NF   C) 3NF   D) BCNF\n"
                        "   • **Correct Answer: B) 2NF** (2NF directly eliminates partial key dependencies).\n\n"
                        "2. **Question 2: Transitive Dependency Test**:\n"
                        "   • If A -> B and B -> C hold (where neither is a super key), which normal form is violated by attribute C?\n"
                        "   • A) 1NF   B) 2NF   C) 3NF   D) BCNF\n"
                        "   • **Correct Answer: C) 3NF** (Transitive dependency through non-key attribute B violates 3NF).\n\n"
                        "3. **Question 3: Boyce-Codd (BCNF) Strict Condition**:\n"
                        "   • Under BCNF, for every non-trivial functional dependency X -> Y, what condition MUST X satisfy?\n"
                        "   • A) X must be prime   B) X must be atomic   C) X must be a Super Key   D) Y must be numeric\n"
                        "   • **Correct Answer: C) X must be a Super Key** (Every determinant in BCNF must be a super key).\n\n"
                        "4. **Question 4: First Normal Form (1NF) Rules**:\n"
                        "   • What is the fundamental requirement for a relation to be in 1NF?\n"
                        "   • A) No foreign keys   B) All attribute values must be atomic   C) Exactly 3 tables   D) Clustered index\n"
                        "   • **Correct Answer: B) All attribute values must be atomic** (No repeating groups or array attributes).\n\n"
                        "💡 **Exam Tip**: In exam questions, always identify ALL Candidate Keys first before testing 2NF and 3NF!"
                    )
                else:
                    return (
                        "❓ **Interactive Academic Practice Quiz**\n\n"
                        "1. **Question 1: Core Fundamentals**:\n"
                        "   • What is the primary operational objective of this concept?\n"
                        "   • A) Reduce memory overhead   B) Guarantee deterministic correctness   C) Minimize complexity   D) All of the above\n"
                        "   • **Correct Answer: D) All of the above** (The foundational theorem addresses all three criteria).\n\n"
                        "2. **Question 2: Practical Application**:\n"
                        "   • Under what operational constraints is this method most effective?\n"
                        "   • A) Unbounded inputs   B) Structured bounded data sets   C) Deprecated protocols   D) Real-time streams\n"
                        "   • **Correct Answer: B) Structured bounded data sets**.\n\n"
                        "3. **Question 3: Edge Case Analysis**:\n"
                        "   • Which common pitfall frequently causes failure during implementation?\n"
                        "   • A) Missing base conditions   B) Over-allocation   C) Race conditions   D) Null references\n"
                        "   • **Correct Answer: A) Missing base conditions**.\n\n"
                        "💡 **Exam Tip**: Review definitions thoroughly and practice edge-case scenarios before the test!"
                    )

            # Mode: Flashcards
            if "flashcard" in q:
                if "normalization" in q or "1nf" in q or "2nf" in q or "3nf" in q or "bcnf" in q or "database" in q or "dbms" in q:
                    return (
                        "📇 **Database Normalization Key Flashcards**\n\n"
                        "1. **Card 1: 1NF Definition & Rule**:\n"
                        "   • *Prompt*: What does 1NF enforce?\n"
                        "   • *Answer*: Every attribute cell must contain atomic (indivisible) values with no repeating groups or arrays.\n\n"
                        "2. **Card 2: 2NF Partial Dependency**:\n"
                        "   • *Prompt*: What dependency does 2NF eliminate?\n"
                        "   • *Answer*: Eliminates Partial Functional Dependencies. Non-prime attributes must depend on the FULL candidate key.\n\n"
                        "3. **Card 3: 3NF Transitive Dependency**:\n"
                        "   • *Prompt*: What is a Transitive Dependency in 3NF?\n"
                        "   • *Answer*: When a non-prime attribute depends on another non-prime attribute (X -> Y where neither is a candidate key).\n\n"
                        "4. **Card 4: BCNF Determinant Rule**:\n"
                        "   • *Prompt*: What is the golden rule of Boyce-Codd Normal Form?\n"
                        "   • *Answer*: In every functional dependency X -> Y, the determinant X MUST be a Super Key.\n\n"
                        "💡 **Pro Tip**: Use spaced repetition to review these 4 cards 20 minutes before revision!"
                    )
                else:
                    return (
                        "📇 **High-Yield Concept Flashcards**\n\n"
                        "1. **Card 1: Core Definition & Meaning**:\n"
                        "   • *Front*: What is the central definition of this topic?\n"
                        "   • *Back*: Foundational principle that structures operations and establishes theoretical baseline.\n\n"
                        "2. **Card 2: Key Formulas & Invariants**:\n"
                        "   • *Front*: What mathematical or logical invariant must hold true?\n"
                        "   • *Back*: Invariant remains consistent across state transitions.\n\n"
                        "3. **Card 3: Typical Exam Question Pattern**:\n"
                        "   • *Front*: How do university professors test this in exams?\n"
                        "   • *Back*: Through derivation, trace table exercises, and counter-example proofs.\n\n"
                        "💡 **Pro Tip**: Review these flashcards daily in 15-minute pomodoro blocks!"
                    )

            # Mode: Exam Prep
            if "exam" in q or "prep" in q:
                return (
                    "📝 **High-Yield Exam Preparation Guide**\n\n"
                    "1. **Critical Theorem Review & Derivations**:\n"
                    "   • Master the core definitions, state transition theorems, and standard proofs.\n"
                    "   • Practice writing the step-by-step mathematical or algorithmic steps without looking at reference notes.\n\n"
                    "2. **Common Exam Traps & Pitfalls**:\n"
                    "   • Watch out for edge-case boundaries (null values, empty sets, overlapping composite keys).\n"
                    "   • Always state assumptions clearly on your exam script before computing final values.\n\n"
                    "3. **Top Scoring Strategy & Time Management**:\n"
                    "   • Allocate 1.5 minutes per mark (e.g. 15 mins for a 10-mark multi-part question).\n"
                    "   • Start with structured analytical steps and draw diagrams to capture partial credits.\n\n"
                    "💡 **Exam Tip**: Solve at least 3 previous years' university examination papers under timed conditions!"
                )

            # Mode: Study Plan
            if "plan" in q or "study plan" in q:
                return (
                    "📅 **Structured 7-Day Academic Study Timetable**\n\n"
                    "1. **Days 1–2: Foundational Axioms & Core Rules**:\n"
                    "   • 45 mins: Comprehensive textbook reading and handwritten summary notes.\n"
                    "   • 30 mins: Diagramming structural models and identifying prime attributes.\n\n"
                    "2. **Days 3–4: In-Depth Problem Solving & Decompositions**:\n"
                    "   • 60 mins: Step-by-step practice problems with progressive difficulty levels.\n"
                    "   • 20 mins: Verifying candidate keys and testing dependency preservation.\n\n"
                    "3. **Days 5–6: Advanced Anomalies & Synthesis**:\n"
                    "   • 45 mins: Exploring edge-case scenarios and comparing alternative approaches.\n"
                    "   • 30 mins: Self-testing with 10-question flashcard drills.\n\n"
                    "4. **Day 7: Timed Mock Exam & Final Polish**:\n"
                    "   • 90 mins: Timed past-paper examination simulation.\n"
                    "   • 30 mins: Highlighting remaining uncertainties for quick morning review.\n\n"
                    "💡 **Study Tip**: Complete each daily block inside the Student Focus Timer for peak retention!"
                )

            # Default: Mode Explain Concept (e.g. Database Normalization 1NF, 2NF, 3NF, BCNF)
            if "normalization" in q or "1nf" in q or "2nf" in q or "3nf" in q or "bcnf" in q or "database" in q or "dbms" in q:
                return (
                    "📚 **Database Normalization Breakdown (1NF, 2NF, 3NF, BCNF)**\n\n"
                    "1. **1NF (First Normal Form)**:\n"
                    "   • Ensures atomic (indivisible) values in each column; no multi-valued attributes.\n"
                    "   • Eliminates repeating groups, arrays, and nested tables from single attributes.\n"
                    "   • Every record has a unique Primary Key that uniquely identifies rows.\n\n"
                    "2. **2NF (Second Normal Form)**:\n"
                    "   • Must already satisfy 1NF.\n"
                    "   • Eliminates Partial Dependencies: Every non-prime attribute must depend on the ENTIRE candidate key, not a subset.\n"
                    "   • Only applies when the Primary Key is composite (made of 2 or more attributes).\n\n"
                    "3. **3NF (Third Normal Form)**:\n"
                    "   • Must already satisfy 2NF.\n"
                    "   • Eliminates Transitive Dependencies: Non-prime attributes must not depend on other non-prime attributes.\n"
                    "   • Rule: For every X -> Y, either X is a Super Key OR Y is a Prime Attribute.\n\n"
                    "4. **BCNF (Boyce-Codd Normal Form)**:\n"
                    "   • Stricter, cleaner version of 3NF that handles overlapping candidate keys.\n"
                    "   • Rule: For EVERY functional dependency X -> Y, X MUST be a Super Key (no exceptions for prime attributes).\n"
                    "   • Eliminates update, insertion, and deletion anomalies completely.\n\n"
                    "💡 **Exam Tip**: In your exam, first compute the Closure of attributes to find all Candidate Keys, then check 2NF, 3NF, and BCNF step-by-step!"
                )
            else:
                return (
                    "📚 **Academic Concept Breakdown & Mastery Notes**\n\n"
                    "1. **Core Terminology & Theoretical Foundations**:\n"
                    "   • Fundamental definitions, operational premises, and architectural scope.\n"
                    "   • Key axioms that govern how components interact within the system.\n\n"
                    "2. **Step-by-Step Mechanisms & Working Principles**:\n"
                    "   • Sequential workflow mapping input states through processing rules to outputs.\n"
                    "   • Mathematical equations, algorithm invariants, and structural properties.\n\n"
                    "3. **Practical Real-World Implementations & Examples**:\n"
                    "   • Production-grade architectural patterns and real-world system integrations.\n"
                    "   • Performance trade-offs, space-time complexities, and optimization tricks.\n\n"
                    "4. **High-Yield Exam Traps & Critical Edge Cases**:\n"
                    "   • Frequent misconceptions in university exams and how to counter them.\n"
                    "   • Verification checklist to achieve full credit in descriptive questions.\n\n"
                    "💡 **Exam Tip**: Structure your answers with clear numbered steps and a labeled diagram for full marks!"
                )
        else:
            return (
                "📖 **AI Reading Companion Insights**\n\n"
                "Based on your literary preferences, this title offers an immersive exploration of themes "
                "that align closely with your reading goals. Perfect for your daily reading sessions!"
            )

# Global Singleton Client
groq_client = GroqClient()
