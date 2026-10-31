# VoidMark Clapback — Compact In-Game Quick Replies

**Current main-branch mode (October 31, 2026):** This addon is now usable entirely inside Classic Era without AI, Windows software, Node.js, or an API key. The companion files remain in the repository as optional legacy/experimental tooling, but they are **not necessary** for quick replies.

## Quick setup

1. Pull the latest main branch.
2. Copy the updated `VoidMarkClapback` directory into `C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\VoidMarkClapback`.
3. Restart the game or type `/reload`.
4. Receive a whisper and click **[CB]**, or type `/clapback`.
5. Choose a style and a reply using the dropdowns. Click **Send** to send one whisper, or **Edit in chat** to review/change before pressing Enter.
6. **Next Player** cycles conversations. **Next Reply** cycles options.

This mode uses 25 authored presets across five styles. It does not generate contextual AI text, automate replies, or message anyone without a deliberate click. Chat logging is not required.

The older Windows-companion details below describe the earlier implementation and are retained for historical reference; their in-game button descriptions are superseded by this section.

---

# VoidMark Clapback 0.1.1

**Minimap button:** left-click the purple chat icon to open/close Clapback. Drag it around the minimap to reposition it; its position is saved per character. Supports round minimaps and square maps that report their shape (including ElvUI). `/clapback` remains available.

Standalone Classic Era whisper addon and Windows AI reply companion. Everything lives in this repository. Loki is not used or modified.

## Start testing

1. Pull **main** in GitHub Desktop, or download this repository's ZIP and extract it.
2. Copy the **VoidMarkClapback** folder into `C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns`. The TOC must be directly inside `AddOns\VoidMarkClapback`. Restart WoW if this is a new addon installation.
3. Install **Node.js 22 or newer** from https://nodejs.org if needed. Windows PowerShell 5.1 and .NET Framework are included with supported Windows installations. No npm install is required.
4. Double-click **Start-Clapback.cmd** from the repository. Keep the `companion` folder beside it.
5. Open **Settings**. Enter your local character as `Name-Realm`, without spaces in the realm name (example: `Taliaa-Thunderfury`). Check the chat-log path. Enter an OpenAI API key with API billing enabled, then Save. ChatGPT subscriptions do not supply API credits. Create/manage keys at https://platform.openai.com/api-keys . Do not paste keys into WoW or GitHub.
6. In WoW, type `/clapback`, then click **Toggle chat log** if logging is OFF. The usual `/chatlog` command also toggles logging. WoW logging writes other chat channels too; the companion only processes player whispers.
7. Have someone send a whisper. Choose that player in the Windows panel, click **Generate / Regenerate**, select a suggestion, and **Copy Reply**. Open their whisper in WoW, paste, check the recipient, and press Enter yourself.
8. If the log is delayed or the player is absent: click **[Clapback]** beside the incoming whisper, **Copy Context**, then **Ctrl+C**. Open the companion with **Ctrl+Alt+C**, click **Paste Context**, then Generate. The imported character must match Settings.

You can also paste a reviewed reply into the addon and click **Prepare Whisper**. This opens the addressed chat edit box; it does not send anything. Replies are limited to 240 UTF-8 bytes by default validation (180 configured by default), below the usual whisper payload limit.

## What is implemented

- Classic Era 1.15.9 / TOC 11509, matching the installed client inspected during development.
- Incoming and outgoing whisper events; separate player/realm conversations; timestamp and available GUID/class/race; line-ID deduplication. Identical text with a different line ID is kept.
- Purple movable addon panel, remembered position, scrollable history, clickable action appended using a chat event filter. Existing player and item links are passed through unchanged.
- Windows native purple panel with player selection, latest whisper, recent context, Quick Replies and Custom AI tabs, six humor styles, 3-5 responses, editable draft, regeneration, copying, tray reopening, optional always-on-top and Ctrl+Alt+C.
- Actual HTTPS OpenAI Responses API integration, strict reply schema, `store:false`, short context, configurable model, byte limits, custom instructions and follow-up refinement. There is no canned-response fallback.
- Read-only polling of WoWChatLog.txt every 500 ms. Starts at the end of an existing file; handles partial lines, UTF-8 boundaries, truncation and replacement. English incoming `Name whispers:` and outgoing `To Name:` formats, including bracketed/hyperlinked names, are recognized. Battle.net whispers and other locales are not supported in this version.
- Automatic generation is OFF initially. Enabling it sends recent whisper context to OpenAI. One request at a time, cooldown, coalescing of rapid incoming whispers, bounded pending conversations, and stale-response rejection. API failures display an error without an endless retry loop.
- API keys encrypted with Windows DPAPI for the current Windows user under `%LOCALAPPDATA%\VoidMarkClapback\key.dpapi`. Settings are separate; keys never enter addon files or SavedVariables. Local HTTP binds only to 127.0.0.1 on a random port and requires a per-run token; browser-origin requests are rejected.

## Important integration boundaries

**The addon cannot receive live AI responses from Windows.** It has no HTTP client or supported live arbitrary-file input. SavedVariables are not a live IPC channel. Clicking [Clapback] selects the in-game conversation only; it cannot activate or select a Windows conversation. Use the companion player selector or the explicit copy-context handoff. AI controls operate in the Windows panel; the addon tabs explain that handoff.

**Real-time game-log flush timing remains unverified.** The existing local Era log contained incoming whispers, confirming a usable format, but no controlled new-whisper timing test was performed. A readable file does not prove logging is currently enabled. Check the addon logging status, and use the test below. No reload is required by the reader, but game buffering can delay availability. Manual context copying avoids that dependency.

The companion never injects memory, simulates game inputs, writes game files, or automatically sends a message. The global hotkey only shows/hides the Windows panel. Use windowed/borderless WoW for an always-on-top panel; exclusive fullscreen may cover it. If the hotkey is unavailable, double-click the tray icon.

## Settings and privacy

Model defaults to `gpt-4.1-mini`; select another Responses API model supporting structured output if your account requires it. All six humor styles are available in the Quick Replies tab. Count, reply length, context size, cooldown, memory retention, automatic generation, on-top behavior, hotkey and log path are configurable.

Only conversation text, speaker roles, prior suggestions and your custom instructions are sent to OpenAI. Player names, GUIDs, log paths, unrelated channels and account details are omitted from prompts. The OpenAI service's own retention and billing policies still apply; `store:false` disables Responses application storage, not every possible provider log.

Companion transcripts are memory-only, bounded to 100 conversations and 2-40 messages each. Idle conversations expire after the configured retention (60 minutes by default); ongoing conversations retain their configured recent-message window. Closing the companion clears them. **Clear history** clears memory and invalidates pending results; it does not delete WoW's own chat log. Settings and the encrypted key persist locally. Delete API key removes that stored key.

The addon keeps up to 20 messages per player, 100 players, and expires conversations idle for an hour. Saved chat history is OFF by default. `/clapback remember` toggles saving it on logout/reload; `/clapback clear` clears it. Position always persists. WoW owns its log and SavedVariables lifecycle.

**Switching alts:** change Local character before monitoring that alt. Changing character or log path clears companion memory and pending results. The plain log does not reliably label your current character, so the companion cannot detect alt switches automatically. Run one companion per log/client; do not point two active game clients at the same log. Unqualified player names are kept distinct from realm-qualified names to avoid silently joining the wrong people; copy context if needed.

## Commands

| Command | Action |
|---|---|
| `/clapback` | Open the addon panel |
| `/clapback Name-Realm` | Select a recorded conversation |
| `/clapback clear` | Clear addon history |
| `/clapback remember` | Toggle saved addon history |
| `/chatlog` | WoW's toggle for chat logging |
| Ctrl+Alt+C | Show/hide Windows companion, if enabled |

## Verification and in-game checklist

Run `node --test tests/*.test.mjs`. Windows tests cover parsing, unrelated-chat rejection, partial UTF-8 writes, startup backlog skipping, truncation/replacement, separate conversations, retention, manual imports, API request construction, error/refusal/length handling, authenticated local HTTP, settings validation, alt isolation, native panel construction/backend connection, and DPAPI roundtrip. API tests use synthetic responses and never spend API credits. `lua5.1 tests/addon.lua` checks Lua syntax and mocked addon event/filter/export contracts. GitHub Actions runs both suites and packages separate addon/Windows ZIP artifacts.

Still requires your environment:

1. Receive a fresh whisper with logging ON. Verify it appears in the companion without reload; note the delay. Repeat with an outgoing reply. If absent, use Copy Context and report the delay/format.
2. With ElvUI enabled, click [Clapback] on two different players. Verify each selects the right history and ordinary name/item links still work. Check whispers shown in multiple chat windows are recorded only once.
3. Save your API key and Generate. Verify 3-5 genuinely generated choices, styles, Custom AI refinements, quota/authentication errors, copy, paste and manual sending. No live paid API request was made during development.
4. Receive another whisper while generation is running; outdated suggestions should be discarded. Switch selected players; replies must remain attached to their own conversation.
5. Drag the addon, reload, confirm its position; verify saved history stays off unless enabled. Test companion settings, hotkey, tray reopening, window position and fullscreen behavior.
6. Confirm the review/prepare button opens the correct recipient without sending. Report any BugGrabber stack trace and your client/ElvUI versions.

Native control construction and backend communication are automated-test verified. Visual layout, interactive Windows hotkey behavior, actual ElvUI integration, and game-log latency are not yet certified. Forever support is intentionally deferred.

## API reference

OpenAI Responses API: https://developers.openai.com/api/reference/resources/responses/methods/create
WoW UI source mirror (for inspection): https://github.com/Gethe/wow-ui-source

All implementation code in this repository is newly written; no third-party addon code was copied.
