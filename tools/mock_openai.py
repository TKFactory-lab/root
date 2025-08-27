"""
Mock OpenAI client for local tests. Use in unit tests to avoid network calls.
"""

def mock_chat_completion(prompt: str) -> str:
    # very small stub that returns a deterministic reply
    return f"[MOCK] received: {prompt}"
