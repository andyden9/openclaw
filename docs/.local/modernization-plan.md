# Docs Modernization Plan

Last updated: 2026-02-11

## What "modernized" means (the playbook)

Based on the PRs already landed (#9648, #8885, #9950, #10416, #10499, #11196, #12761), modernized pages share these traits:

1. **Mintlify components** — `<Steps>`, `<Tip>`, `<Note>`, `<Warning>`, `<Accordion>`, `<AccordionGroup>`, `<Tabs>`, `<Tab>`, `<CardGroup>`, `<Card>` instead of raw markdown lists and walls of prose.
2. **Task-oriented structure** — quick start at top, config next, reference last. Readers answer "how do I do X" before "how does X work internally."
3. **Deduplication** — each page has one job. Split overview vs. reference when a page mixes quickstart prose with exhaustive field lists.
4. **Symptom-first troubleshooting** — commands to run, expected output, log signatures, deep links.
5. **Cross-linking** — deliberate "Related:" blocks and "Next:" footers; no island pages.
6. **Scanability** — short paragraphs, Accordion-collapsed detail, Tips for gotchas, Warnings for data-loss risks.

## Quality metrics (before/after signal)

| Page                                   | Lines | Mintlify components | Status       |
| -------------------------------------- | ----: | :-----------------: | ------------ |
| `tools/subagents` (gold standard)      |   470 |         22          | ✅ Done      |
| `help/troubleshooting` (gold standard) |   265 |          8          | ✅ Done      |
| `install/index` (gold standard)        |   211 |         31          | ✅ Done      |
| `gateway/configuration`                |  3448 |        **0**        | 🔴 Untouched |
| `channels/telegram`                    |   800 |        **0**        | 🔴 Untouched |
| `channels/discord`                     |   476 |        **0**        | 🔴 Untouched |
| `channels/whatsapp`                    |   406 |        **0**        | 🔴 Untouched |
| `gateway/doctor`                       |   282 |        **0**        | 🔴 Untouched |
| `concepts/session`                     |   204 |        **0**        | 🔴 Untouched |
| `concepts/model-failover`              |   149 |        **0**        | 🔴 Untouched |
| `concepts/oauth`                       |   145 |        **0**        | 🔴 Untouched |

---

## Priority 1 — The elephant: `gateway/configuration.md`

**Why first:** 3,448 lines, 86 headings, zero components. Every user touches this page. It's the longest page in the entire docs by a wide margin.

### Problems

- Monolithic: 86 `##`/`###` headings in a single flat scroll.
- Mixes tutorial-style examples (minimal config, self-chat mode) with exhaustive field reference (every channel, every agent default, every model provider).
- No Accordions — users looking for "how do I set Telegram groups" must scroll past WhatsApp, env vars, auth storage, cron, etc.
- No Tabs — channel-specific config (WhatsApp vs Telegram vs Discord vs Slack) is interleaved instead of tabbed.
- Provider-specific config (OpenCode Zen, z.ai, Moonshot, MiniMax, LM Studio, etc.) is embedded here instead of living on provider pages.
- Config Includes, RPC methods (`config.apply`, `config.patch`) are tutorial content mixed into the reference.

### Plan

1. **Split into 2 pages:**
   - `gateway/configuration.md` — overview + common tasks (Accordions for each domain: channels, agents, sessions, models, sandbox, gateway server). Each Accordion has the most-used fields, a config snippet, and a link to the full reference.
   - `gateway/configuration-reference.md` (new) — full field list grouped by section, each section in an Accordion. This is the page AI agents and power users grep.
2. **Move provider config examples** to their respective provider pages (`providers/ollama.md`, `providers/venice.md`, etc.) and link back. The configuration page should not be a provider catalog.
3. **Move RPC methods** (`config.apply`, `config.patch`, `config.get`) to `reference/rpc.md` or a dedicated `gateway/config-rpc.md` — they're API reference, not user config.
4. **Add Mintlify components:**
   - `<AccordionGroup>` for the domain sections (Channels, Agents, Sessions, Models, Gateway, Plugins, Hooks).
   - `<Tabs>` inside channel config for WhatsApp / Telegram / Discord / Slack / Signal / iMessage.
   - `<Tip>` for "recommended starting point" and "use `openclaw config set` for quick changes."
   - `<Warning>` for strict validation ("Gateway refuses to start on unknown keys").
   - `<Steps>` for the "first config" walkthrough.
5. **Keep Config Includes** on the main page but wrap in an `<Accordion>` (power-user feature).

### Estimated effort: Large (2-3 sessions). Do in stages — split first, then component-ify.

---

## Priority 2 — Channel pages (WhatsApp, Telegram, Discord, Slack, Signal, iMessage)

**Why next:** 2,824 lines combined, zero Mintlify components across all six. These are the pages users land on during setup. They all follow the same shape but none use Steps/Tabs/Tips.

### Problems (shared across all six)

- Setup instructions are numbered lists in plain markdown — should be `<Steps>`.
- Config examples are raw code blocks with no context boxes — should have `<Tip>` for recommended values and `<Warning>` for security pitfalls.
- Multi-account config is buried in prose — should be `<Accordion>` (advanced topic).
- Group chat config is dense — should use `<Tabs>` (single group vs wildcard vs per-channel).
- Troubleshooting sections (when they exist) are not linked to the central troubleshooting hub.
- No consistent "Related:" footer linking to pairing, routing, configuration.
- WhatsApp-specific: "Goals" and "Architecture (who owns what)" sections read like internal design docs, not user docs.

### Plan (per page, applied to all six)

1. **`<Steps>` for Quick Setup** — wrap the existing numbered setup flow in `<Steps>` with clear titles ("Create bot token", "Configure OpenClaw", "Start the gateway", "Approve pairing").
2. **`<Tip>` / `<Warning>` boxes:**
   - Tip: "Use `openclaw onboard` for an interactive setup" (where applicable).
   - Warning: "Enable an allowlist or pairing before exposing to the internet."
   - Note: "Multi-account support requires `channels.<channel>.accounts`."
3. **`<Accordion>` for advanced sections:** Multi-account, webhook mode (Telegram), group policy deep-dive, reactions, media handling.
4. **`<Tabs>` for DM policy options:** pairing vs allowlist vs open (shared pattern across channels).
5. **Consistent footer:** "Related: [Pairing](/channels/pairing) · [Channel Routing](/channels/channel-routing) · [Troubleshooting](/help/troubleshooting)"
6. **Trim internal design notes** — move "Architecture (who owns what)" style content to code comments or AGENTS.md; keep user-facing behavior only.

### Order within this tier

1. `channels/telegram.md` (800L — longest, most features, highest traffic)
2. `channels/discord.md` (476L)
3. `channels/whatsapp.md` (406L)
4. `channels/slack.md` (574L)
5. `channels/imessage.md` (340L)
6. `channels/signal.md` (228L)

### Estimated effort: Medium per page (1 session each). Can be parallelized.

---

## Priority 3 — Concepts cluster (12 untouched pages)

**Why:** The "Agents" tab's concepts are the "understand how it works" layer. They're short (35–204 lines) and read like dev notes. Quick wins with high leverage because other pages link to them.

### Pages and what each needs

| Page                              | Lines | Top changes needed                                                                                                                                                   |
| --------------------------------- | ----: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `concepts/compaction.md`          |    61 | Self-referencing anchor link (links to itself). Add `<Steps>` for the compaction flow. Add `<Tip>` for when to use `/compact`.                                       |
| `concepts/queue.md`               |    89 | Add `<Tabs>` for queue modes (steer / followup / collect / steer-backlog). Add `<Note>` for defaults. Config example needs `<Accordion>`.                            |
| `concepts/streaming.md`           |   135 | Two streaming layers (block + Telegram draft) should be `<Tabs>`. Chunking algorithm should be `<Accordion>`. Config controls need a summary table or `<CardGroup>`. |
| `concepts/model-failover.md`      |   149 | Add `<Steps>` for the failover flow (profile rotation → model fallback). Cooldown backoff table. `<Warning>` for "OAuth can look lost."                              |
| `concepts/oauth.md`               |   145 | Add `<Steps>` for setup-token flow and OAuth flow. Add `<Tabs>` for Anthropic vs OpenAI auth. `<Warning>` for token sink behavior.                                   |
| `concepts/session-tool.md`        |   193 | Add examples. Wrap tool descriptions in `<Accordion>` or a table.                                                                                                    |
| `concepts/typing-indicators.md`   |    68 | Small — add a comparison table for modes. `<Tip>` for recommended mode.                                                                                              |
| `concepts/retry.md`               |    69 | Small — add a table for defaults. `<Note>` for per-provider behavior.                                                                                                |
| `concepts/presence.md`            |   102 | Dev-facing. Add `<Accordion>` for merge rules and TTL. Low priority.                                                                                                 |
| `concepts/usage-tracking.md`      |    35 | Stub. Expand with `<Tabs>` for each surface (chat, CLI, menu bar).                                                                                                   |
| `concepts/markdown-formatting.md` |   130 | Dev-facing pipeline doc. Add `<Accordion>` for per-channel rendering. Low priority unless users hit formatting issues.                                               |
| `concepts/timezone.md`            |    91 | Add `<Tip>` for the recommended approach. Cross-link to `date-time.md`.                                                                                              |

### Order: compaction → queue → streaming → model-failover → oauth → session-tool → typing/retry (batched small wins) → the rest.

### Estimated effort: Small per page (15-30 min each). Batch 3-4 per session.

---

## Priority 4 — Gateway operations cluster (13 untouched pages)

**Why:** Users debugging production issues land here. The troubleshooting hub (#11196) already links into these pages, but the targets themselves are raw.

### Pages and what each needs

| Page                                            | Lines | Top changes needed                                                                                                                                                        |
| ----------------------------------------------- | ----: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gateway/doctor.md`                             |   282 | Long numbered migration list → `<Accordion>` per migration group. "What it does" summary → `<Steps>`. Quick start flags → `<Tabs>` (interactive / headless / automation). |
| `gateway/logging.md`                            |   113 | Add `<Tabs>` for file vs console vs WS logging. Config examples need `<Accordion>`. `<Tip>` for "verbose ≠ file log level."                                               |
| `gateway/discovery.md`                          |   116 | Transport comparison → `<CardGroup>` or table. Bonjour TXT keys → `<Accordion>`.                                                                                          |
| `gateway/protocol.md`                           |   221 | Dev-facing. Add `<Accordion>` for frame types. Lower priority.                                                                                                            |
| `gateway/multiple-gateways.md`                  |   112 | Add `<Steps>` for multi-gateway setup. `<Warning>` for port conflicts.                                                                                                    |
| `gateway/health.md`                             |    35 | Stub — mostly duplicates `help/troubleshooting`. Consider merging or expanding with `<Steps>` for the diagnostic ladder.                                                  |
| `gateway/gateway-lock.md`                       |    34 | Tiny. Add `<Note>` box. Could merge into `gateway/index.md`.                                                                                                              |
| `gateway/openai-http-api.md`                    |   118 | Add `<Steps>` for enabling the endpoint + curl examples.                                                                                                                  |
| `gateway/openresponses-http-api.md`             |   317 | Same treatment as openai-http-api.                                                                                                                                        |
| `gateway/background-process.md`                 |    93 | Add `<Accordion>` for env overrides. `<Tabs>` for exec vs process tool.                                                                                                   |
| `gateway/bridge-protocol.md`                    |    89 | Legacy/removed. Mark with `<Warning>` deprecated banner.                                                                                                                  |
| `gateway/sandbox-vs-tool-policy-vs-elevated.md` |   128 | Decision guide → `<CardGroup>` comparison or a table with `<Tip>` for recommended approach.                                                                               |
| `gateway/pairing.md`                            |    99 | Add `<Steps>` for the pairing flow.                                                                                                                                       |
| `gateway/tools-invoke-http-api.md`              |    85 | Add `<Steps>` + curl examples.                                                                                                                                            |

### Order: doctor → logging → health (merge/expand) → sandbox-vs-tool-policy → the rest.

### Estimated effort: Small-Medium per page.

---

## Priority 5 — Nodes & media pages (5 untouched)

| Page                        | Lines | Top changes needed                                                                                                                                                 |
| --------------------------- | ----: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `nodes/audio.md`            |   114 | Add `<Accordion>` for config examples (3 variants). `<Steps>` for auto-detection flow. `<Tip>` for recommended setup. Date stamp in title ("2026-01-17") — remove. |
| `nodes/talk.md`             |    90 | Add `<Steps>` for the talk-mode loop. `<Accordion>` for voice directives. Config → `<Tabs>` (macOS / iOS / Android).                                               |
| `nodes/voicewake.md`        |    65 | Add `<Steps>` for setup. `<Tip>` for recommended wake word.                                                                                                        |
| `nodes/images.md`           |    72 | Add config examples with `<Accordion>`.                                                                                                                            |
| `nodes/location-command.md` |   113 | Add `<Steps>` for setup.                                                                                                                                           |

### Estimated effort: Small per page.

---

## Priority 6 — Web interfaces + misc

| Page               | Lines | Top changes needed                                                                                                                     |
| ------------------ | ----: | -------------------------------------------------------------------------------------------------------------------------------------- |
| `web/webchat.md`   |    49 | Stub. Expand or merge into `web/control-ui.md`.                                                                                        |
| `web/dashboard.md` |    46 | Overlaps with `web/control-ui.md`. Merge or differentiate.                                                                             |
| `web/index.md`     |   116 | Add `<CardGroup>` for the web surfaces.                                                                                                |
| `tts.md`           |   396 | Root-level orphan. Move content to `nodes/talk.md` or a proper nav location. Add `<Tabs>` for providers (ElevenLabs / OpenAI / local). |
| `logging.md`       |   350 | Root-level orphan. Overlaps with `gateway/logging.md`. Merge or make one the user guide and one the reference.                         |
| `date-time.md`     |   128 | Overlaps with `concepts/timezone.md`. Merge.                                                                                           |

### Estimated effort: Small-Medium. Some of these are merge/redirect decisions.

---

## Priority 7 — CLI reference pages (36 pages, mostly stubs)

Most CLI pages are 16-50 line stubs with a command and a few examples. They're functional but feel auto-generated.

### Batch treatment

- Add `<Tip>` for the most common flags.
- Add "Related:" links to the concept/feature page.
- Expand the highest-traffic ones: `cli/config.md`, `cli/status.md`, `cli/sessions.md`, `cli/gateway.md`.
- Leave the rest as-is (low traffic, correct content).

### Estimated effort: Small. Can be done in one batch session.

---

## Priority 8 — Provider pages (stubs)

Several provider pages are stubs (33-64 lines): `glm`, `zai`, `openrouter`, `qwen`, `xiaomi`, `venice`.

### Treatment

- Add `<Steps>` for setup.
- Add config examples from `gateway/configuration.md` (move them here).
- Add `<Tip>` for recommended models.
- Expand `openrouter` (37L) — it's a popular provider with a lot of config surface.

### Estimated effort: Small per page.

---

## Execution order (recommended)

| Phase       | Pages                                                                | Sessions |
| ----------- | -------------------------------------------------------------------- | -------- |
| **Phase 1** | `gateway/configuration.md` (split + componentify)                    | 2-3      |
| **Phase 2** | Channel pages (telegram → discord → whatsapp → slack)                | 4        |
| **Phase 3** | Concepts batch (compaction, queue, streaming, model-failover, oauth) | 2        |
| **Phase 4** | Gateway ops (doctor, logging, sandbox-vs-policy)                     | 2        |
| **Phase 5** | Nodes + media (audio, talk, voicewake)                               | 1        |
| **Phase 6** | Web + orphan merges (tts, logging, date-time, webchat)               | 1        |
| **Phase 7** | CLI reference batch                                                  | 1        |
| **Phase 8** | Provider stubs                                                       | 1        |

Total: ~14-16 sessions to modernize the full docs surface.

---

## Pages that should NOT be modernized (intentionally internal/dev-facing)

- `docs/refactor/*` — internal design docs
- `docs/experiments/*` — proposals and plans
- `docs/security/*` — threat model and contributing guide (separate audience)
- `docs/reference/templates/*` — raw template content
- `docs/platforms/mac/xpc.md`, `signing.md`, `child-process.md`, `release.md` — dev setup docs
- `docs/.i18n/*` — translation pipeline
- `docs/zh-CN/*`, `docs/ja-JP/*` — generated translations (pipeline handles these)
