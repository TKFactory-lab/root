#!/bin/bash
cd /usr/src/redmine || exit 1
bundle exec rails runner /tmp/get_user_tokens.rb > /tmp/user_tokens_out.txt 2>&1 || true
cat /tmp/user_tokens_out.txt || true
