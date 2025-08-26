def test_process_message_happy_path():
    from tools.example_tool import process_message
    out = process_message({'text': 'こんにちは'})
    assert isinstance(out, dict)
    assert out['reply'].startswith('受け取った: こんにちは')


def test_process_message_type_error():
    from tools.example_tool import process_message
    try:
        process_message({'text': 123})
        assert False, 'TypeError expected'
    except TypeError:
        assert True
