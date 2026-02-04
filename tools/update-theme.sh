#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/discovery-survey/plugin-admin"
LATEST_URL="${REPO}/releases/latest"
ZIP_NAME="theme-admin.zip"

LIME_ROOT="/home/survey-user/limesurvey"
DEST_DIR="${LIME_ROOT}/upload/themes/admin"

log()  { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
err()  { printf '%s\n' "$*" >&2; }

get_latest_tag() {
  local final_url tag
  final_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$LATEST_URL")"
  tag="${final_url##*/}"
  [[ -n "$tag" ]] || return 1
  printf '%s' "$tag"
}

main() {
  command -v wget  >/dev/null 2>&1 || { err "[ERROR] wget is required."; exit 1; }
  command -v unzip >/dev/null 2>&1 || { err "[ERROR] unzip is required."; exit 1; }

  local tag asset_url tmp_dir zip_path extract_dir admin_dir

  tag="$(get_latest_tag)"
  asset_url="${REPO}/releases/download/${tag}/${ZIP_NAME}"

  log "[INFO] Latest release tag: ${tag}"
  log "[INFO] Checking asset: ${asset_url}"

  if ! wget -q --spider --max-redirect=20 "$asset_url"; then
    warn "[INFO] Asset not found (skip): ${asset_url}"
    exit 0
  fi

  tmp_dir=""
    trap '[[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"' EXIT
    tmp_dir="$(mktemp -d)"

    zip_path="${tmp_dir}/${ZIP_NAME}"
    extract_dir="${tmp_dir}/extracted"

    log "[INFO] Downloading ${ZIP_NAME}..."
    wget -q --tries=3 --timeout=30 -O "$zip_path" "$asset_url"

    log "[INFO] Extracting..."
    mkdir -p "$extract_dir"
    unzip -q "$zip_path" -d "$extract_dir"

    # Ищем admin/ внутри распаковки
    admin_dir="$(find "$extract_dir" -maxdepth 5 -type d -name admin -print -quit || true)"
    if [[ -z "${admin_dir:-}" ]]; then
      err "[ERROR] admin/ folder not found inside zip."
      err "[DEBUG] Extracted top-level:"
      find "$extract_dir" -maxdepth 2 -mindepth 1 -print >&2 || true
      exit 1
    fi

    log "[INFO] Found admin dir: ${admin_dir}"
    log "[INFO] Copying admin/* -> ${DEST_DIR}"

    mkdir -p "$DEST_DIR"

    # Важно: не пытаемся сохранять owner/group (иначе chgrp/chown ошибки)
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --no-owner --no-group "${admin_dir}/" "${DEST_DIR}/"
    else
      cp -a "${admin_dir}/." "${DEST_DIR}/"
    fi

    log "[OK] Done."
}

main "$@"
