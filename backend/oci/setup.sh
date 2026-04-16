#!/usr/bin/env bash
# SprintOps — configuración local tipo práctica (source setup.sh).
# No crea ATP ni OKE: solo recopila variables y escribe local-env.sh (gitignore).
# IAM: grupo sprintops-group + políticas en policies-iam.txt (una vez).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/local-env.sh"

echo "================================================================================"
echo "SprintOps OCI — setup (grupo IAM: sprintops-group)"
echo "================================================================================"
echo "Antes de seguir:"
echo "  • Identity → Groups → sprintops-group (tu usuario dentro)."
echo "  • Identity → Policies → editor manual → pegar backend/oci/policies-iam.txt"
echo "  • Autonomous Database: créala en la consola si aún no existe; aquí solo guardamos la JDBC."
echo "================================================================================"
read -r -p "Pulsa Enter para continuar… " _

prompt() {
  local var="$1"
  local text="$2"
  local secret="${3:-0}"
  local val=""
  if [ "$secret" = "1" ]; then
    read -r -s -p "$text" val || true
    echo
  else
    read -r -p "$text" val || true
  fi
  printf -v "$var" '%s' "$val" || return 1
}

echo ""
echo "--- Docker / OCIR (misma idea que build.sh) ---"
prompt DOCKER_REGISTRY "DOCKER_REGISTRY (ej. iad.ocir.io/namespace/repo-sprintops): " 0

echo ""
echo "--- Oracle ATP (JDBC; desde OCI → tu ATP → DB Connection) ---"
prompt SPRING_DATASOURCE_URL "SPRING_DATASOURCE_URL (jdbc:oracle:thin:@//...): " 0
prompt SPRING_DATASOURCE_USERNAME "SPRING_DATASOURCE_USERNAME [ADMIN]: " 0
SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-ADMIN}"
prompt SPRING_DATASOURCE_PASSWORD "SPRING_DATASOURCE_PASSWORD: " 1

echo ""
echo "--- Opcional ---"
prompt OCI_REGION "OCI_REGION (ej. iad) [Enter para vacío]: " 0
prompt GROQ_MODEL "GROQ_MODEL [llama-3.3-70b-versatile]: " 0
GROQ_MODEL="${GROQ_MODEL:-llama-3.3-70b-versatile}"

echo ""
echo "--- Groq + Telegram + frontend (obligatorios para deploy.sh) ---"
prompt GROQ_API_KEY "GROQ_API_KEY: " 1
prompt APP_TELEGRAM_BOT_TOKEN "APP_TELEGRAM_BOT_TOKEN: " 1
prompt APP_TELEGRAM_BOT_USERNAME "APP_TELEGRAM_BOT_USERNAME (sin @): " 0
prompt APP_FRONTEND_BASE_URL "APP_FRONTEND_BASE_URL (https://... o http://IP:5173): " 0

required_vars=(DOCKER_REGISTRY SPRING_DATASOURCE_URL SPRING_DATASOURCE_USERNAME SPRING_DATASOURCE_PASSWORD GROQ_API_KEY APP_TELEGRAM_BOT_TOKEN APP_TELEGRAM_BOT_USERNAME APP_FRONTEND_BASE_URL)
for v in "${required_vars[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "Error: $v no puede estar vacío."
    exit 1
  fi
done

umask 077
{
  echo "# Generado por oci/setup.sh — no subir a Git."
  echo "export DOCKER_REGISTRY=$(printf '%q' "$DOCKER_REGISTRY")"
  echo "export SPRING_DATASOURCE_URL=$(printf '%q' "$SPRING_DATASOURCE_URL")"
  echo "export SPRING_DATASOURCE_USERNAME=$(printf '%q' "$SPRING_DATASOURCE_USERNAME")"
  echo "export SPRING_DATASOURCE_PASSWORD=$(printf '%q' "$SPRING_DATASOURCE_PASSWORD")"
  echo "export GROQ_API_KEY=$(printf '%q' "$GROQ_API_KEY")"
  echo "export GROQ_MODEL=$(printf '%q' "$GROQ_MODEL")"
  echo "export APP_TELEGRAM_BOT_TOKEN=$(printf '%q' "$APP_TELEGRAM_BOT_TOKEN")"
  echo "export APP_TELEGRAM_BOT_USERNAME=$(printf '%q' "$APP_TELEGRAM_BOT_USERNAME")"
  echo "export APP_FRONTEND_BASE_URL=$(printf '%q' "$APP_FRONTEND_BASE_URL")"
  if [ -n "${OCI_REGION:-}" ]; then
    echo "export OCI_REGION=$(printf '%q' "$OCI_REGION")"
  else
    echo "unset OCI_REGION 2>/dev/null || true"
  fi
} >"$OUT"
chmod 600 "$OUT"

echo ""
echo "================================================================================"
echo "SETUP VERIFIED — escrito: $OUT"
echo "================================================================================"
echo "Los scripts oci/build.sh y oci/deploy.sh cargan ese archivo automáticamente."
echo "Opcional (como en la práctica): añade a ~/.bashrc"
echo "  source $OUT"
echo "================================================================================"

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  # shellcheck source=/dev/null
  source "$OUT"
  echo "(Variables exportadas en esta sesión porque ejecutaste: source oci/setup.sh)"
fi
