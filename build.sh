#!/usr/bin/env bash
# llms-full.txt 를 생성한다. 원본은 개별 .md 파일이고 이 산출물은 손으로 고치지 않는다.
# 로컬: ./build.sh   /   CI: .github/workflows/build.yml 이 같은 스크립트를 부른다
set -euo pipefail
cd "$(dirname "$0")"

DOCS=(nakama.md godot.md agents.md ops.md)
OUT=llms-full.txt
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

{
  echo "# Wooick Cho — 기술 노트 (전문)"
  echo
  echo "생성 $NOW · 소스 커밋 \`$COMMIT\` · 이 파일은 자동 생성물이다."
  echo "원본은 개별 문서이며 이 파일을 직접 고치면 다음 빌드에 덮어써진다."
  echo
  echo "조우익(Wooick Cho)이 진행하는 프로젝트들에서 실측한 사실만 모은 것."
  echo "문서에 없거나 문서와 다른 것, 시간을 실제로 잡아먹은 것만 적는다."
  echo "각 사실에는 불변 ID와 측정일·버전이 붙어 있다. 버전 의존 사실이므로 그 밖에서는"
  echo "유효하지 않을 수 있다."
  echo
  echo "개별 문서: $(printf 'https://chowooick.github.io/%s ' "${DOCS[@]}")"
  echo
  for f in "${DOCS[@]}"; do
    echo "---"
    echo
    echo "<!-- source: $f -->"
    echo
    cat "$f"
    echo
  done
} > "$OUT"

n=$(grep -cE '^## [A-Z]{3}-[0-9]{3} ' "${DOCS[@]}" | awk -F: '{s+=$2} END{print s}')
echo "생성: $OUT ($(wc -c < "$OUT" | tr -d ' ')B, 사실 ${n}건, 커밋 $COMMIT)"

# ID 중복 검사 — 중복은 인용을 깨뜨리므로 빌드를 실패시킨다
dup=$(grep -hoE '^## [A-Z]{3}-[0-9]{3}' "${DOCS[@]}" | sort | uniq -d)
if [ -n "$dup" ]; then
  echo "오류: ID 중복" >&2
  echo "$dup" >&2
  exit 1
fi
echo "ID 중복 없음"
