#!/usr/bin/env bash
# claude-harness 전역 설치 (macOS / Linux)
# 골격 agents/ 와 skills/ 를 ~/.claude 로 설치한다. examples/ 는 설치하지 않는다.
#
# 사용법:
#   ./install.sh             복사 설치 (기본)
#   ./install.sh --symlink   심볼릭 링크 설치 (repo 갱신 즉시 반영)

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude"
MODE="copy"
[ "${1:-}" = "--symlink" ] && MODE="symlink"

mkdir -p "$TARGET/agents" "$TARGET/skills"

install_item() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  if [ "$MODE" = "symlink" ]; then
    ln -s "$src" "$dst"; echo "  link  $dst"
  else
    cp -R "$src" "$dst"; echo "  copy  $dst"
  fi
}

echo "claude-harness → $TARGET ($MODE)"

echo "[agents]"
for f in "$REPO"/agents/*.md; do
  install_item "$f" "$TARGET/agents/$(basename "$f")"
done

echo "[skills]"
for d in "$REPO"/skills/*/; do
  name="$(basename "$d")"
  install_item "${d%/}" "$TARGET/skills/$name"
done

echo "완료. 새 Claude Code 세션에서 /orchestrate 로 진입하세요."
