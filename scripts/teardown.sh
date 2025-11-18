#!/bin/bash

# Credit: ChatGPT
# This function is meant to create a clean-slate between deployments

set -euo pipefail

# --- Variables ---
ROOT_DIR="$(pwd)/.."          # Script is run from /scripts
INFRA_DIR="${ROOT_DIR}/infra/aws"

APP_SECRET_NAME="app-config"
DB_SECRET_NAME="db-secret"

# Optional Rekognition ARN (pass as first argument)
REKOGNITION_ARN="${1:-}"

# --- Functions ---
function log_info() {
    echo -e "[INFO] $*"
}

function log_error() {
    echo -e "[ERROR] $*" >&2
}

function terraform_destroy() {
    log_info "Starting Terraform destroy in ${INFRA_DIR}..."
    (
        cd "$INFRA_DIR" || exit 1
        terraform destroy -auto-approve
    )
    log_info "Terraform destroy completed."
}

function delete_secret() {
    local secret_name="$1"
    log_info "Deleting secret: ${secret_name}..."
    if aws secretsmanager delete-secret \
        --secret-id "${secret_name}" \
        --force-delete-without-recovery; then
        log_info "Secret ${secret_name} deleted successfully."
    else
        log_error "Failed to delete secret ${secret_name} (it may not exist). Continuing..."
    fi
}

function stop_rekognition_model() {
    local arn="$1"
    log_info "Stopping Rekognition project version: ${arn}..."
    if ! output=$(aws rekognition stop-project-version --project-version-arn "${arn}" --region "${AWS_REGION:-us-east-1}" 2>&1); then
        log_error "Failed to stop Rekognition model. Output:"
        log_error "${output}"
    else
        log_info "Rekognition model stop requested successfully."
    fi
}

# --- Main Script ---
log_info "=== Starting teardown ==="

terraform_destroy

delete_secret "${APP_SECRET_NAME}"
delete_secret "${DB_SECRET_NAME}"

if [[ -n "${REKOGNITION_ARN}" ]]; then
    stop_rekognition_model "${REKOGNITION_ARN}"
else
    log_info "No Rekognition ARN provided. Skipping Rekognition stop."
fi

log_info "=== Teardown completed successfully ==="
exit 0
