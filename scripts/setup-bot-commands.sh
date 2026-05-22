#!/usr/bin/env bash
# Publish the bot's command list to Telegram so they show up in the '/'
# menu inside the chat. Run once after the bot is created, and again
# whenever the command set changes.
#
# Reads TELEGRAM_BOT_TOKEN from .env in the repo root.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Missing .env in $(pwd). Copy .env.example and fill in TELEGRAM_BOT_TOKEN." >&2
  exit 1
fi

# Load TELEGRAM_BOT_TOKEN without leaking the rest of .env into the shell.
TELEGRAM_BOT_TOKEN="$(grep -E '^TELEGRAM_BOT_TOKEN=' .env | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'")"

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "TELEGRAM_BOT_TOKEN is empty in .env" >&2
  exit 1
fi

curl -fsS -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMyCommands" \
  -H 'Content-Type: application/json' \
  -d '{
    "commands": [
      {"command": "generate", "description": "Create a new post now"},
      {"command": "schedule", "description": "Show or set daily schedule (HH:MM, off)"},
      {"command": "help",     "description": "Show available commands"}
    ]
  }'
echo
echo "Bot commands published."
