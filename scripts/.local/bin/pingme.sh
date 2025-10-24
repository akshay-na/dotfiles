#!/bin/sh

# PingMe CLI Wrapper Script
# Supports Slack, Discord, and easily expandable to other platforms
# Usage: ./pingme.sh <platform> <title-type> <message>
# Example: ./pingme.sh slack ALERT "Database connection failed"
# Example: ./pingme.sh discord SUCCESS "Deployment completed successfully"

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0")"
DEFAULT_PLATFORM="discord"
DEFAULT_MESSAGE="This is a test message"

# POSIX-compatible function to get title by type
get_title() {
  title_type=$1
  timestamp=$(date)

  case "$title_type" in
  ALERT) echo "🚨 ALERT - $timestamp" ;;
  NOTIFICATION) echo "📢 NOTIFICATION - $timestamp" ;;
  STATUS_UPDATE) echo "📊 STATUS UPDATE - $timestamp" ;;
  WARNING) echo "⚠️ WARNING - $timestamp" ;;
  ERROR) echo "❌ ERROR - $timestamp" ;;
  SUCCESS) echo "✅ SUCCESS - $timestamp" ;;
  INFO) echo "ℹ️ INFO - $timestamp" ;;
  MAINTENANCE) echo "🔧 MAINTENANCE - $timestamp" ;;
  BACKUP) echo "💾 BACKUP - $timestamp" ;;
  DEPLOYMENT) echo "🚀 DEPLOYMENT - $timestamp" ;;
  *)
    echo "UNKNOWN - $timestamp"
    ;;
  esac
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
  echo "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
  echo "${RED}[ERROR]${NC} $1" >&2
}

success() {
  echo "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
  echo "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
  cat <<EOF
${SCRIPT_NAME} - PingMe CLI Wrapper Script

USAGE:
    ${SCRIPT_NAME} <platform> <title-type> <message>

ARGUMENTS:
    platform     Target platform (slack, discord)
    title-type   Predefined title type (see list below)
    message      Message content

EXAMPLES:
    ${SCRIPT_NAME} slack ALERT "Database connection failed"
    ${SCRIPT_NAME} discord SUCCESS "Deployment completed successfully"
    ${SCRIPT_NAME} slack BACKUP "Daily backup finished"
    ${SCRIPT_NAME} discord MAINTENANCE "Scheduled maintenance starting in 5 minutes"

AVAILABLE TITLE TYPES:
$(printf "    %-15s %s\n" "ALERT" "🚨 ALERT")
$(printf "    %-15s %s\n" "NOTIFICATION" "📢 NOTIFICATION")
$(printf "    %-15s %s\n" "STATUS_UPDATE" "📊 STATUS UPDATE")
$(printf "    %-15s %s\n" "WARNING" "⚠️ WARNING")
$(printf "    %-15s %s\n" "ERROR" "❌ ERROR")
$(printf "    %-15s %s\n" "SUCCESS" "✅ SUCCESS")
$(printf "    %-15s %s\n" "INFO" "ℹ️ INFO")
$(printf "    %-15s %s\n" "MAINTENANCE" "🔧 MAINTENANCE")
$(printf "    %-15s %s\n" "BACKUP" "💾 BACKUP")
$(printf "    %-15s %s\n" "DEPLOYMENT" "🚀 DEPLOYMENT")

ENVIRONMENT VARIABLES:
    SLACK_TOKEN     Slack bot token (required for Slack)
    DISCORD_TOKEN   Discord webhook URL (required for Discord)

SUPPORTED PLATFORMS:
    slack          Send message to Slack
    discord        Send message to Discord

NOTES:
    - All three arguments are required
    - Title types are case-sensitive and must match exactly
    - Each title includes an emoji and timestamp automatically
EOF
}

# Check dependencies
check_dependencies() {
  missing_deps=""

  # Check if pingme is installed
  if ! command -v pingme >/dev/null 2>&1; then
    missing_deps="$missing_deps pingme"
  fi

  # Check if curl is available (needed for installation)
  if ! command -v curl >/dev/null 2>&1; then
    missing_deps="$missing_deps curl"
  fi

  # Report missing dependencies
  if [ -n "$missing_deps" ]; then
    error "Missing required dependencies:$missing_deps"
    error ""

    for dep in $missing_deps; do
      case "$dep" in
      pingme)
        error "PingMe CLI is not installed or not in PATH"
        error "Installation options:"
        error "  1. Homebrew: brew install kha7iq/tap/pingme"
        error "  2. Shell script: curl -sL https://bit.ly/installpm | sudo sh"
        error "  3. Manual: https://github.com/kha7iq/pingme/releases"
        ;;
      curl)
        error "curl is required for installation but not found"
        error "Please install curl using your system package manager"
        ;;
      esac
    done

    error ""
    error "After installing dependencies, run this script again."
    exit 1
  fi

  # Verify pingme version if available
  if command -v pingme >/dev/null 2>&1; then
    pingme_version=$(pingme --version 2>/dev/null || echo "unknown")
    log "PingMe version: $pingme_version"
  fi
}

# Validate platform
validate_platform() {
  local platform="$1"
  case "$platform" in
  slack | discord)
    return 0
    ;;
  *)
    error "Unsupported platform: $platform"
    error "Supported platforms: slack, discord"
    return 1
    ;;
  esac
}

# Validate title type
validate_title_type() {
  local title_type="$1"
  if [[ -n "$(get_title $title_type)" ]]; then
    return 0
  else
    error "Invalid title type: $title_type"
    return 1
  fi
}

# Check required environment variables
check_env_vars() {
  local platform="$1"

  case "$platform" in
  slack)
    if [[ -z "${SLACK_TOKEN:-}" ]]; then
      error "SLACK_TOKEN environment variable is not set"
      error "Please set your Slack bot token: export SLACK_TOKEN='your-token'"
      return 1
    fi
    ;;
  discord)
    if [[ -z "${DISCORD_TOKEN:-}" ]]; then
      error "DISCORD_TOKEN environment variable is not set"
      error "Please set your Discord webhook URL: export DISCORD_TOKEN='your-webhook-url'"
      return 1
    fi
    ;;
  esac
}

# Send message to Slack
send_slack() {
  local title="$1"
  local message="$2"

  log "Sending message to Slack..."
  log "Title: $title"
  log "Message: $message"

  if pingme slack \
    --token "$SLACK_TOKEN" \
    --channel "$SLACK_CHANNEL_NAME" \
    --title "$title" \
    --msg "$message"; then
    success "Message sent to Slack successfully"
  else
    error "Failed to send message to Slack"
    return 1
  fi
}

# Send message to Discord
send_discord() {
  local title="$1"
  local message="$2"

  log "Sending message to Discord..."
  log "Title: $title"
  log "Message: $message"

  if pingme discord \
    --token "$DISCORD_TOKEN" \
    --channel "$DISCORD_CHANNEL_ID" \
    --title "$title" \
    --msg "$message"; then
    success "Message sent to Discord successfully"
  else
    error "Failed to send message to Discord"
    return 1
  fi
}

# Main send function
send_message() {
  local platform="$1"
  local title="$2"
  local message="$3"

  case "$platform" in
  slack)
    send_slack "$title" "$message"
    ;;
  discord)
    send_discord "$title" "$message"
    ;;
  *)
    error "Unsupported platform: $platform"
    return 1
    ;;
  esac
}

# Parse command line arguments
parse_arguments() {
  local platform
  local title_type
  local message

  case $# in
  3)
    # Three arguments - platform, title-type, message
    platform="$1"
    title_type="$2"
    message="$3"
    ;;
  *)
    error "Exactly 3 arguments are required: <platform> <title-type> <message>"
    error ""
    error "Usage: ${SCRIPT_NAME} <platform> <title-type> <message>"
    error ""
    error "Example: ${SCRIPT_NAME} slack ALERT \"Database connection failed\""
    error "Example: ${SCRIPT_NAME} discord SUCCESS \"Deployment completed\""
    error ""
    error "Run '${SCRIPT_NAME} --help' for more information."
    exit 1
    ;;
  esac

  # Validate platform
  if ! validate_platform "$platform"; then
    exit 1
  fi

  # Validate title type
  if ! validate_title_type "$title_type"; then
    exit 1
  fi

  # Check environment variables
  if ! check_env_vars "$platform"; then
    exit 1
  fi

  # Return parsed values
  echo "$platform|$title_type|$message"
}

# Main function
main() {
  # Handle help flag
  if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  # Check dependencies
  check_dependencies

  # Parse arguments
  local parsed_args
  parsed_args=$(parse_arguments "$@")

  # Extract parsed values (POSIX-safe)
  IFS='|'
  set -- $parsed_args
  platform=$1
  title_type=$2
  message=$3
  IFS=' '

  # Get the actual title from the title type
  local title
  title=$(get_title "$title_type")

  # Log configuration
  log "Configuration:"
  log "  Platform: $platform"
  log "  Title Type: $title_type"
  log "  Title: $title"
  log "  Message: $message"

  # Send message
  if send_message "$platform" "$title" "$message"; then
    exit 0
  else
    exit 1
  fi
}

# Run main function with all arguments
main "$@"
