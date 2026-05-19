# rently-content-agent

Self-hosted [n8n](https://n8n.io/) deployment that will power Rently's
social-media content agent. Same `docker-compose.yml` is intended to run both
locally (now) and on a server (later). See `CLAUDE.md` for project context and
roadmap.

## Stack

| Component | Image | Role |
|---|---|---|
| n8n | `n8nio/n8n:latest` | Workflow engine + UI (port 5678). Uses built-in SQLite for state. |

One service. n8n stores workflows / credentials / executions in a single
SQLite file inside the `n8n_data` Docker volume.

## Quickstart (local)

Prerequisites: Docker (Docker Desktop / OrbStack / colima).

```bash
# 1. Copy env template
cp .env.example .env

# 2. Generate the encryption key — paste into N8N_ENCRYPTION_KEY in .env
openssl rand -hex 32

# 3. Start n8n
docker compose up -d

# 4. Watch logs until you see "Editor is now accessible via" or similar
docker compose logs -f n8n

# 5. Open http://localhost:5678 and create the owner account.
```

**Back up `.env` somewhere safe immediately.** Losing `N8N_ENCRYPTION_KEY` = losing every stored credential (Telegram tokens, Meta tokens, etc).

## Day-to-day commands

```bash
# Stop the stack (keeps data)
docker compose down

# Stop AND wipe local data (fresh start, deletes all workflows)
docker compose down -v

# Restart n8n (e.g. after editing .env)
docker compose restart n8n

# Tail logs
docker compose logs -f n8n

# Update to a newer n8n image
docker compose pull && docker compose up -d
```

## Backing up data

All n8n state lives in the `n8n_data` Docker volume. To back it up:

```bash
# One-shot backup of the SQLite DB
docker compose exec n8n cat /home/node/.n8n/database.sqlite > backup-$(date +%Y-%m-%d).sqlite

# Restore (with the stack stopped)
docker compose down
docker run --rm -v rently-content-agent_n8n_data:/data -v $(pwd):/backup alpine \
  cp /backup/backup-2026-05-19.sqlite /data/database.sqlite
docker compose up -d
```

We'll automate this on the server later.

## Hello-world: scheduled Telegram message

A quick smoke test that exercises the full stack end-to-end.

**Telegram side (5 min):**

1. Message `@BotFather` in Telegram → `/newbot` → pick a name and username
   (must end in `bot`, e.g. `rently_admin_bot`) → **save the bot token**.
2. Message your new bot once from your personal Telegram (any text).
3. Visit `https://api.telegram.org/bot<TOKEN>/getUpdates` in a browser →
   copy the numeric `chat.id` (your Telegram user ID).

**n8n side:**

1. **+ Create workflow** → name it `ping-self`.
2. **Add first step → Schedule Trigger** → "Trigger Interval" = every 5 minutes.
3. **Add next node → Telegram → Send a text message**.
   - Credential: "Create New" → paste the bot token from BotFather.
   - Chat ID: your numeric ID.
   - Text: `Hello from n8n — {{ $now }}`
4. **Save** the workflow, then toggle **Active** in the top-right.
5. Within ~5 minutes, a Telegram message arrives. Stack validated.

## Gotchas

- **Never change `N8N_ENCRYPTION_KEY` after first run.** All credentials
  stored in n8n become unrecoverable. Back up `.env` outside the repo.
- **`WEBHOOK_URL` must match how you actually reach n8n.** For local:
  `http://localhost:5678`. For production: `https://your-domain`.
- **`n8nio/n8n:latest` is fine for local development**, but pin a specific
  version before going to production so behavior is reproducible.
- **Workflows live in n8n's SQLite, not in git.** n8n Free Edition has no
  Source Control feature. Don't put production-critical work into workflows
  until a versioning approach is in place.
- **Execution history grows forever by default.** If the SQLite file gets
  large (>1 GB), set `EXECUTIONS_DATA_PRUNE=true` and `EXECUTIONS_DATA_MAX_AGE`
  (in hours) in `.env` to auto-prune old executions.

## What's NOT here yet (deferred)

- Production server deployment
- Reverse proxy / HTTPS (e.g. Caddy in front of n8n on the server)
- Workflow export / git versioning
- Automated database backup
- Claude (content generation), fal.ai (images), Meta publishers — all later

## Files

```
.
├── docker-compose.yml      # n8n only (SQLite-backed)
├── .env.example            # template — copy to .env and fill the encryption key
├── .gitignore
├── workflows/              # placeholder for future workflow exports
├── CLAUDE.md               # project context + roadmap (planning notes)
└── README.md               # this file
```
