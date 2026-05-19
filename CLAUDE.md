# Rently Content Agent — Planning Notes

Compacted notes from initial discussion. **No final decisions made yet** — options
and tradeoffs only. Update this file as decisions get locked in.

## Goal

Build a content agent that:
1. Generates social media content (text + image, later video)
2. Publishes to multiple platforms (Facebook, Instagram first; Telegram, TikTok later)
3. Supports both autonomous and human-in-the-loop modes (configurable)

This is a separate project from `rently-fe`. The web app may expose a thin admin
UI (review queue, "generate now" trigger) but the agent itself lives outside.

## Phasing

| Phase | Scope |
|---|---|
| 1 | Facebook + Instagram, text + image |
| 2 | Telegram, TikTok |
| 3 | Video generation |

## Functional Requirements

- **Review toggle**: per-post (or per-channel) setting to require human approval
  before publishing, or auto-publish. Must be configurable, not hardcoded.
- **Trigger modes** (TBD): on-demand only, scheduled only, or both
- **Content sources** (TBD): rental listings, editorial topics, external events,
  or a mix
- **Image strategy** (TBD): existing listing photos, AI-generated, or hybrid
- **Multi-platform fan-out**: same content adapted per platform

## Platform Requirements

### Facebook + Instagram (Meta Graph API)
- One integration covers both platforms
- Requires:
  - Facebook Page (not personal profile)
  - Instagram **Business or Creator** account linked to the Page
    (personal IG accounts cannot post via API)
  - Meta App registered at developers.facebook.com
  - Permissions: `pages_manage_posts`, `pages_read_engagement`,
    `instagram_basic`, `instagram_content_publish`
  - **App Review** required by Meta (days to weeks, needs business verification
    + screencast demo) — start early
  - Long-lived Page access tokens (60-day, refresh flow needed)
- Instagram extra constraints:
  - Images must be hosted at a public HTTPS URL (no direct binary upload)
  - Strict aspect-ratio rules
  - 25 posts/day per account limit

### Telegram (later)
- Bot API — trivial setup, no review process
- Can ship in minutes

### TikTok (later)
- Content Posting API — requires app review
- Video-only
- Stricter content rules

## Tech Options (no decision yet)

### Workflow / orchestration platform

| Option | Pros | Cons |
|---|---|---|
| **n8n** (self-hosted) | Biggest ecosystem, pre-built Meta/Telegram/AI nodes, visual debugging, OSS community edition | Git sync is Enterprise-only on free tier (workflows live in DB; export via CLI) |
| **Activepieces** | Fully OSS, **native git sync in free version**, similar feature set | Smaller community than n8n |
| **Make.com** | Cloud-only, polished | Paid, no self-host |
| **Pipedream** | Code-in-UI hybrid | Less integration breadth |
| **Windmill** | Script + workflow hybrid, dev-friendly | Smaller ecosystem |
| **Pure code (TypeScript)** + Inngest/Trigger.dev | Full control, easy git, step functions with retries | Build all OAuth/posting integrations from scratch |

Key tradeoff: workflow platforms save weeks on OAuth + posting integrations;
code-first is more flexible for agent reasoning and image composition.

### LLM (text)
- **Anthropic Claude** via `@anthropic-ai/sdk` — tool use for structured output,
  prompt caching for brand voice
- (Or via workflow platform's Anthropic node)

### Image generation
- **fal.ai** (Flux 1.1 Pro) — ~$0.04/image, ~3s, simple REST
- **Replicate** — Flux models, slower
- **OpenAI DALL-E 3 / gpt-image-1** — pricier, decent quality
- **Stable Diffusion** self-hosted — free but ops overhead

### Image composition (text overlays, brand frames on listing photos)
- **@vercel/og (Satori)** — JSX → PNG, templated
- **sharp** — crop / resize / aspect ratio for IG
- Skip entirely if going raw AI images only

### Storage
- **Supabase Postgres** — drafts, schedule, post history, review state
- **Supabase Storage** (public bucket) — generated images at public HTTPS URLs
  (required by Instagram)

### Publishing clients
- **Meta Graph API** — raw `fetch`, thin wrapper (skip the giant Meta SDK)
- **Telegram Bot API** — raw `fetch`
- **TikTok Content Posting API** — raw `fetch`
- (Or use workflow platform's built-in nodes)

## Hosting Options

| Option | Cost | Notes |
|---|---|---|
| **Own server (Docker)** | Free if already owned | Best fit — user has a server. Needs Docker, public HTTPS, persistent volume, ~1GB+ RAM |
| **n8n Cloud** | €20/mo+ | Zero ops; workflows in their DB |
| **Oracle Cloud Free Tier** | Free | Generous ARM VM, annoying signup, can be reclaimed |
| **Hetzner CX22** | ~€4.50/mo | Cheap, reliable |
| **Fly.io / Railway free tiers** | Free with limits | Sleep on inactivity — breaks cron triggers |
| **Local Docker** | Free | Only on when machine is on — kills scheduled posts |

### Server hosting requirements (if self-hosting workflow platform)
- Docker + Docker Compose
- ~1GB RAM, 1 CPU minimum (2GB+ comfortable)
- Public HTTPS URL (e.g. `n8n.domain.com`) — needed for Meta webhooks
  and secure login
- Ports 80 + 443 open
- Persistent volume for app data + encryption key
- Reverse proxy with auto-TLS (Caddy or Traefik recommended)

Typical compose stack:
```
n8n (or activepieces)
postgres        # more reliable than SQLite default
caddy/traefik   # reverse proxy + HTTPS
```

## Repo Strategy Options

- **No repo** — n8n Cloud only; workflows live in their DB
- **Tiny infra repo** — `rently-content-agent/` with:
  ```
  docker-compose.yml
  .env.example
  workflows/        # exported JSON, source of truth
  scripts/
    export.sh       # n8n export:workflow --all
    import.sh       # n8n import:workflow --separate
  README.md
  ```
- **Full code repo** — if going pure-code (TypeScript + Inngest etc.)

The folder currently sits at `/Users/surebr3c/dev/rently/rently-content-agent/`
ready for whichever shape gets picked.

## Secrets / Config to Plan For

- Meta long-lived Page access tokens (encrypted at rest, refresh job)
- Instagram Business Account ID
- Facebook Page ID
- Meta App ID + App Secret
- Telegram Bot token (when added)
- TikTok API credentials (when added)
- LLM API key (Anthropic)
- Image gen API key (fal.ai / Replicate / OpenAI)
- Supabase URL + service-role key
- Webhook verification tokens

Multi-tenant later: a `channels` table per (page, ig_account, token).

## Integration With rently-fe

Optional and minimal:
- `/admin/content` review page (UI only — calls agent webhooks)
- Read access to listings table for content source
- Shared Supabase project (recommended) or separate DB

No agent logic in `rently-fe`. The agent owns:
- Generation
- Scheduling
- Publishing
- Retry / failure handling
- Post history

## Open Decisions

1. **Workflow platform vs pure code** (n8n / Activepieces / TypeScript)
2. **Trigger model**: on-demand / scheduled / both
3. **Content source**: listings / editorial / hybrid
4. **Image strategy**: real photos / AI / hybrid
5. **Hosting**: own server / cloud / free tier
6. **Review default**: on or off per channel
7. **rently-fe integration depth**: shared DB / separate DB / webhook only
8. **Multi-tenant from day one or single-channel first**

## Critical Path Items (start early regardless of choices)

- Meta App registration + business verification + App Review submission
  (longest lead time — weeks)
- Instagram Business Account setup linked to Facebook Page
- Decide brand voice / style guide (prompt input)
