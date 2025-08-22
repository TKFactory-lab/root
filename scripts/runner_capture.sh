#!/bin/bash
# wrapper to capture rails runner stdout/stderr reliably
OUT=/tmp/runner_capture_out.txt
echo "RUN_AT=$(date --iso-8601=seconds)" > "$OUT"
echo "PWD=$(pwd)" >> "$OUT"
echo "WHOAMI=$(whoami)" >> "$OUT"
echo "RUBY=$(ruby -v 2>&1)" >> "$OUT"
echo "RAILS=$(rails -v 2>&1)" >> "$OUT"
echo "---- RUN ----" >> "$OUT"
set -o pipefail
if rails runner -e production "$1" >> "$OUT" 2>&1; then
  echo "EXIT=0" >> "$OUT"
else
  echo "EXIT=$?" >> "$OUT"
fi
echo "---- END ----" >> "$OUT"
cat "$OUT"
