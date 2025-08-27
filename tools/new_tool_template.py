"""
New tool template for CrewAI agents.

Placeholders and examples for adding a tool and wiring it into `project_manager.py`'s tools list.
"""
import os
import json
from typing import Any, Dict

try:
    from crewai import tool
except Exception:
    # fallback decorator used in project_manager.py for environments without crewai package
    def tool(name=None):
        def _decorator(fn):
            try:
                fn.__crewai_tool_name__ = name
            except Exception:
                pass
            return fn

        return _decorator


@tool("Echo Tool")
def echo_tool(payload: Dict[str, Any]) -> str:
    """Simple example tool: returns an echo of input text.

    Expected payload: {"text": "..."}
    """
    text = payload.get("text") if isinstance(payload, dict) else str(payload)
    return f"echo: {text}"


def example_usage():
    print(echo_tool({"text": "hello"}))


if __name__ == '__main__':
    example_usage()
