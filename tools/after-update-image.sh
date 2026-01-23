#!/usr/bin/env bash
set -u

LIME_ROOT="/home/survey-user/limesurvey"
DEST_DIR="${LIME_ROOT}/config"

RAW_BASE="https://raw.githubusercontent.com/LimeSurvey/LimeSurvey/refs/tags"
SERVICE_NAME="limesurvey"

# Usage:
#   ./update-config.sh '6.16.4+260113'
#   ./update-config.sh '6.16.4%2B260113'
LS_REF_RAW="${1:-6.16.4+260113}"
LS_REF="${LS_REF_RAW//+/%2B}"  # encode '+' for GitHub raw

PHP_MEM="${PHP_MEM:-1G}"

cd "$LIME_ROOT" || { echo "[ERROR] Cannot cd to ${LIME_ROOT}"; exit 1; }
mkdir -p "$DEST_DIR" || { echo "[ERROR] Cannot create ${DEST_DIR}"; exit 1; }

PATHS=(
  "application/config/config-defaults.php"
  "application/config/config-sample-dblib.php"
  "application/config/config-sample-mysql.php"
  "application/config/config-sample-pgsql.php"
  "application/config/config-sample-sqlsrv.php"
  "application/config/console.php"
  "application/config/email.php"
  "application/config/fonts.php"
  "application/config/index.html"
  "application/config/internal.php"
  "application/config/ldap.php"
  "application/config/packages.php"
  "application/config/questiontypes.php"
  "application/config/rest.php"
  "application/config/routes.php"
  "application/config/tcpdf.php"
  "application/config/updater_version.php"
  "application/config/vendor.php"
  "application/config/version.php"
)

echo "LimeSurvey ref/tag: ${LS_REF_RAW} (used as: ${LS_REF})"
echo "Working dir: ${LIME_ROOT}"
echo "Download to: ${DEST_DIR}"
echo

for relpath in "${PATHS[@]}"; do
  filename="$(basename "$relpath")"
  dest="${DEST_DIR}/${filename}"
  url="${RAW_BASE}/${LS_REF}/${relpath}"
  bak="${dest}.bak"

  # permissions check
  if [[ -e "$dest" && ! -w "$dest" ]]; then
    echo "[ERROR] No write permission for file: $dest"
    echo "        Run as survey-user or fix ownership/permissions."
    echo
    continue
  fi
  if [[ ! -e "$dest" && ! -w "$DEST_DIR" ]]; then
    echo "[ERROR] No write permission for directory: $DEST_DIR"
    echo "        Run as survey-user or fix ownership/permissions."
    echo
    continue
  fi

  if [[ -f "$dest" ]]; then
    echo "[INFO] Exists: ${dest} -> will replace"
    if ! cp -p "$dest" "$bak" 2>/dev/null; then
      echo "[WARN] Cannot create backup: ${bak} (continuing anyway)"
    fi
  else
    echo "[INFO] Missing: ${dest} -> will create"
    rm -f "$bak" >/dev/null 2>&1 || true
  fi

  if wget -q --tries=3 --timeout=20 -O "$dest" "$url"; then
    rm -f "$bak" >/dev/null 2>&1 || true
    echo "[OK] Updated: ${filename}"
  else
    echo "[ERROR] Failed to download: ${url}"
    echo "        Reverting/cleanup and continuing..."

    if [[ -f "$bak" ]]; then
      mv -f "$bak" "$dest" >/dev/null 2>&1 || true
      echo "        Restored backup: ${filename}"
    else
      rm -f "$dest" >/dev/null 2>&1 || true
      echo "        Removed partial file: ${filename}"
    fi

    echo
    continue
  fi

  echo
done

echo "[INFO] Running docker checks..."
if ! docker compose exec "$SERVICE_NAME" bash -lc '
echo "Container:"; cat /etc/hostname;
echo "version.php:"; head -n 20 /var/www/html/application/config/version.php;
'; then
  echo "[ERROR] docker compose exec (check) failed."
  exit 1
fi

echo
echo "[INFO] Running updatedb..."
if ! docker compose exec "$SERVICE_NAME" php -d "memory_limit=${PHP_MEM}" application/commands/console.php updatedb; then
  echo "[ERROR] updatedb failed."
  exit 1
fi

echo
echo "[INFO] Running flushassets..."
if ! docker compose exec "$SERVICE_NAME" php -d "memory_limit=${PHP_MEM}" application/commands/console.php flushassets; then
  echo "[ERROR] flushassets failed."
  exit 1
fi

echo
echo "Done."
