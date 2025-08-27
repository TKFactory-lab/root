import sys
import os
import pytest

# add tools to sys.path for import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))

from new_tool_template import echo_tool
from mock_openai import mock_chat_completion


def test_echo_tool():
    res = echo_tool({'text': 'こんにちは'})
    assert 'echo:' in res


def test_mock_openai():
    r = mock_chat_completion('hello')
    assert r.startswith('[MOCK]')
