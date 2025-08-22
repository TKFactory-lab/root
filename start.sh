#!/bin/bash

# Redmineサービスが利用可能になるのを待機
# HTTPで到達可能か確認する。10秒間隔で最大30回リトライ（最大5分）
for i in $(seq 1 30); do
  if curl -sSf "http://redmine:3000/" >/dev/null 2>&1; then
    echo "Redmineサービスが利用可能になりました！"
    break
  else
    echo "Redmineサービスが利用可能になるのを待機しています... ($i/30)"
    sleep 10
  fi
done

# スクリプトを実行
python project_manager.py

# project_manager.py は一度処理を実行して終了する想定のため
# コンテナがすぐ終了して再起動を繰り返さないよう、
# 正常終了後はプロセスをフォアグラウンドで待機させます。
exec tail -f /dev/null
