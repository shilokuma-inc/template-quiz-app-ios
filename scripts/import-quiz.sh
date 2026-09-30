#!/bin/bash
#
# Content/ の問題 CSV（categories.csv / questions.csv）を検証し、
# アプリに同梱する <アプリ名>/Resources/quiz.json に変換する。
#
# 使い方:
#   scripts/import-quiz.sh           CSV から quiz.json を生成する
#   scripts/import-quiz.sh --check   quiz.json が CSV の内容と一致しているか確認する（CI 用）
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# アプリ名は .xcodeproj の名前から求める（rename.sh で名前を変えても動くように）
project=$(basename -s .xcodeproj ./*.xcodeproj)

case "${1:-}" in
  "") command=import ;;
  --check) command=check ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 1
    ;;
esac

swift run --quiet --package-path Packages/QuizKit quiz-tool "$command" Content "$project/Resources/quiz.json"
