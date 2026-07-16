#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${WORKDIR:-$ROOT_DIR/work}"
ORCALOCA_REPO="${ORCALOCA_REPO:-https://github.com/fishmingyu/OrcaLoca.git}"
ORCALOCA_COMMIT="${ORCALOCA_COMMIT:-4bfcae9a1e48b7e9c2b5a199c34da0ccc4ca9ec1}"
AGENTLESS_REPO="${AGENTLESS_REPO:-https://github.com/OpenAutoCoder/Agentless.git}"
AGENTLESS_COMMIT="${AGENTLESS_COMMIT:-8b8a44259a93c5dccf4e5192b7ee7a0735902a85}"

mkdir -p "$WORKDIR"

if [ ! -d "$WORKDIR/OrcaLoca/.git" ]; then
  git clone "$ORCALOCA_REPO" "$WORKDIR/OrcaLoca"
fi

cd "$WORKDIR/OrcaLoca"
git fetch origin "$ORCALOCA_COMMIT"
git checkout "$ORCALOCA_COMMIT"

if [ ! -d third_party/Agentless/.git ]; then
  rm -rf third_party/Agentless
  git clone "$AGENTLESS_REPO" third_party/Agentless
fi
git -C third_party/Agentless fetch origin "$AGENTLESS_COMMIT"
git -C third_party/Agentless checkout "$AGENTLESS_COMMIT"

if git apply --check "$ROOT_DIR/patches/orcaloca_verified_support.patch"; then
  git apply "$ROOT_DIR/patches/orcaloca_verified_support.patch"
else
  echo "OrcaLoca patch is already applied or does not match this checkout." >&2
fi

if [ -d third_party/Agentless/.git ]; then
  if git -C third_party/Agentless apply --check "$ROOT_DIR/patches/agentless_verified_repair.patch"; then
    git -C third_party/Agentless apply "$ROOT_DIR/patches/agentless_verified_repair.patch"
  else
    echo "Agentless patch is already applied or does not match this checkout." >&2
  fi
else
  echo "ERROR: third_party/Agentless is missing or is not a git checkout." >&2
  exit 1
fi

echo "Patched checkout: $WORKDIR/OrcaLoca"
