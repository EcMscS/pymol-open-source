#!/bin/bash
set -euo pipefail

# Only run in Claude Code remote environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

INSTALL_PREFIX="${CLAUDE_PROJECT_DIR}/install-prefix"
PYTHON_SITE="${INSTALL_PREFIX}/local/lib/python3.11/dist-packages"

# ── 1. System dependencies ──────────────────────────────────────────────────
apt-get update -qq
apt-get install -y --no-install-recommends \
  catch2 \
  libfreetype6-dev \
  libglew-dev \
  libglm-dev \
  libmsgpack-dev \
  libnetcdf-dev \
  libpng-dev \
  libxml2-dev \
  python3-dev

# ── 2. Python dependencies ───────────────────────────────────────────────────
pip install --quiet \
  "setuptools<68" \
  biopython \
  flake8 \
  numpy \
  Pillow \
  pytest

# ── 3. mmtf-cpp headers (needed for MMTF fast-load support) ─────────────────
if [ ! -d "${CLAUDE_PROJECT_DIR}/include/mmtf" ]; then
  git clone --quiet --depth 1 https://github.com/rcsb/mmtf-cpp.git /tmp/mmtf-cpp
  cp -R /tmp/mmtf-cpp/include/mmtf* "${CLAUDE_PROJECT_DIR}/include/"
  rm -rf /tmp/mmtf-cpp
fi

# ── 4. Build PyMOL C extension ───────────────────────────────────────────────
if [ ! -f "${PYTHON_SITE}/pymol/_cmd"*.so 2>/dev/null ]; then
  cd "${CLAUDE_PROJECT_DIR}"
  python3 setup.py --no-vmd-plugins install --prefix="${INSTALL_PREFIX}"
fi

# ── 5. Export PYTHONPATH for the session ────────────────────────────────────
echo "export PYTHONPATH=\"${PYTHON_SITE}:\${PYTHONPATH:-}\"" >> "${CLAUDE_ENV_FILE}"
