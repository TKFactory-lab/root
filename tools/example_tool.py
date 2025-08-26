"""例: シンプルなツール（エージェントから呼ばれる想定）
関数: process_message(data: dict) -> dict
- 入力: {'text': str}
- 出力: {'reply': str}
"""

from typing import Dict


def process_message(data: Dict) -> Dict:
    text = data.get('text', '')
    if not isinstance(text, str):
        raise TypeError('text must be a string')
    # 単純なエコー + 長さ情報
    reply = f"受け取った: {text} (len={len(text)})"
    return {'reply': reply}


if __name__ == '__main__':
    # 単体確認用の簡易CLI
    import sys, json
    if len(sys.argv) > 1:
        try:
            data = json.loads(sys.argv[1])
        except Exception:
            data = {'text': sys.argv[1]}
    else:
        data = {'text': 'hello'}
    print(process_message(data))
