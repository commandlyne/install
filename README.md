<p align="center">
  <img src="https://raw.githubusercontent.com/clawworker/install/main/assets/logo.png" alt="ClawWorker" width="200" />
</p>

<h1 align="center">ClawWorker</h1>
<h3 align="center">Your AI Assistant, Everywhere.</h3>

<p align="center">
  <strong>One binary. Every cloud. Every channel. Every LLM.</strong>
</p>

<p align="center">
  <a href="#-quick-install">Install</a> &bull;
  <a href="#-what-is-clawworker">What is it?</a> &bull;
  <a href="#-features">Features</a> &bull;
  <a href="#-supported-platforms">Platforms</a> &bull;
  <a href="#-configuration">Configuration</a> &bull;
  <a href="#-updating">Updating</a> &bull;
  <a href="#-uninstall">Uninstall</a>
</p>

<p align="center">
  <a href="https://github.com/clawworker/install/releases/latest"><img src="https://img.shields.io/github/v/release/clawworker/install?style=flat-square&color=00C853&label=latest" alt="Latest Release" /></a>
  <a href="https://github.com/clawworker/install/releases"><img src="https://img.shields.io/github/downloads/clawworker/install/total?style=flat-square&color=2196F3" alt="Downloads" /></a>
  <img src="https://img.shields.io/badge/platforms-linux%20%7C%20macOS-blueviolet?style=flat-square" alt="Platforms" />
  <img src="https://img.shields.io/badge/arch-amd64%20%7C%20arm64-orange?style=flat-square" alt="Architectures" />
</p>

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash
```

That's it. The installer automatically detects your OS and architecture, downloads the correct binary, verifies its checksum, and installs ClawWorker as a background service.

### Install Options

```bash
# Install a specific version
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- --version v1.2.0

# Install without registering as a service
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- --no-service

# Choose the service mode (default: gateway)
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- --mode serve

# Custom install directory
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- --install-dir /opt/bin
```

---

## What is ClawWorker?

ClawWorker is a **single-binary AI assistant** that deploys anywhere — your laptop, a cloud VM, a Raspberry Pi, or a Kubernetes cluster. It connects your favorite LLMs to 15+ messaging platforms, 40+ built-in tools, and a beautiful Web UI, all from one lightweight process.

Think of it as your **personal AI gateway**: connect once, reach everywhere.

### Why ClawWorker?

| Pain Point | ClawWorker Solution |
|---|---|
| Juggling multiple AI tools | One binary, one config, all providers |
| Setting up AI on a server | Install in 30 seconds, runs as a service |
| Connecting AI to Telegram/Discord/Slack | Built-in channel adapters, zero code |
| Managing context and memory | Persistent memory with vector search |
| Running AI workflows | 40+ tools: shell, files, browser, web search, cron |
| Scaling across teams | OpenAI-compatible API, multi-session, multi-user |

---

## Features

### Multi-Provider LLM Support

Connect to **any major LLM provider** with a single config change. Switch models on the fly.

| Provider | Models |
|---|---|
| **OpenAI** | GPT-4o, GPT-4 Turbo, o1, o3 |
| **Anthropic** | Claude Opus, Sonnet, Haiku |
| **Google** | Gemini Pro, Flash, Ultra |
| **OpenRouter** | 200+ models, one API |
| **Ollama** | Llama, Mistral, Phi — run locally |
| **Vertex AI** | Google Cloud managed models |
| **Mistral** | Mistral Large, Medium, Small |
| **Groq** | Ultra-fast inference |
| **Cerebras** | High-performance AI chips |
| **XAI** | Grok models |
| + more | LiteLLM, Cloudflare Workers AI, Venice AI |

### 15+ Messaging Channels

Deploy once, chat from anywhere. Each channel is a first-class integration, not a webhook hack.

**Chat:** Telegram, Discord, Slack, WhatsApp, Signal, Matrix, IRC, LINE, Feishu/Lark, Nextcloud Talk, Google Chat, DingTalk, Mattermost, Teams, QQ

**Other:** Gmail, Twitch, iMessage (via BlueBubbles), Nostr, Voice calls (Telnyx)

### 40+ Built-in Tools

ClawWorker isn't just a chatbot — it's an **agent** that gets things done.

- **System** — Execute shell commands, manage processes
- **Files** — Read, write, edit, search across your filesystem
- **Browser** — Navigate, screenshot, extract content from the web
- **Search** — Brave, Tavily, Perplexity-powered web search
- **Media** — Generate images (DALL-E), process PDFs, audio, video, OCR
- **Memory** — Persistent long-term memory with vector search
- **Automation** — Cron jobs, scheduled tasks, templates
- **Multi-agent** — Spawn sub-agents for parallel workflows

### Beautiful Interfaces

- **Web UI** — Embedded htmx chat interface, zero setup
- **Terminal UI** — Rich bubbletea TUI for power users
- **CLI** — One-shot queries or interactive REPL
- **REST API** — OpenAI-compatible endpoints for programmatic access

### Enterprise-Ready

- **Encrypted vault** for API keys and secrets
- **Tool policies** — fine-grained allow/deny/approval controls
- **Auth failover** — multiple API keys with round-robin rotation
- **Hot reload** — update config without restarting (SIGHUP)
- **OpenTelemetry** — observability built in
- **Tailscale** — secure remote access without port forwarding

---

## Supported Platforms

| Platform | Architecture | Status |
|---|---|---|
| **Linux** | x86_64 (amd64) | Fully supported |
| **Linux** | ARM64 (aarch64) | Fully supported |
| **macOS** | Intel (amd64) | Fully supported |
| **macOS** | Apple Silicon (arm64) | Fully supported |

**Service integration:**
- **Linux** — systemd user service (auto-start on login)
- **macOS** — LaunchAgent (auto-start on login)

---

## Configuration

After installation, configure ClawWorker with the interactive onboarding wizard:

```bash
clawworker onboard
```

Or set environment variables:

```bash
export CLAWWORKER_PROVIDER=openai      # openai | anthropic | gemini | openrouter | ollama
export CLAWWORKER_API_KEY=sk-...       # Your API key
export CLAWWORKER_MODEL=gpt-4o         # Model name
```

Configuration is stored at `~/.clawworker/config.json`. All settings can also be configured via environment variables prefixed with `CLAWWORKER_`.

### Run Modes

```bash
# One-shot question
clawworker agent -m "Summarize this week's news in AI"

# Interactive terminal
clawworker agent

# Terminal UI (rich interface)
clawworker tui

# Web server (http://localhost:8080)
clawworker serve

# Full gateway — Web UI + all messaging channels
clawworker gateway
```

### Enable Messaging Channels

Just add the token for any channel and restart:

```bash
# Telegram
export CLAWWORKER_TELEGRAM_TOKEN=your-bot-token

# Discord
export CLAWWORKER_DISCORD_TOKEN=your-bot-token

# Slack
export CLAWWORKER_SLACK_BOT_TOKEN=xoxb-...
export CLAWWORKER_SLACK_APP_TOKEN=xapp-...
```

ClawWorker auto-detects configured channels and connects to them on startup.

---

## Updating

### Automatic Update

```bash
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- update
```

This stops the service, downloads the latest binary, and restarts the service.

### Update to a Specific Version

```bash
curl -fsSL https://raw.githubusercontent.com/clawworker/install/main/install.sh | bash -s -- update v1.3.0
```

### Built-in Update Check

```bash
clawworker update
```

---

## Uninstall

### Linux

```bash
systemctl --user stop clawworker
systemctl --user disable clawworker
rm ~/.config/systemd/user/clawworker.service
systemctl --user daemon-reload
sudo rm /usr/local/bin/clawworker
```

### macOS

```bash
launchctl unload ~/Library/LaunchAgents/ai.clawworker.clawworker.plist
rm ~/Library/LaunchAgents/ai.clawworker.clawworker.plist
sudo rm /usr/local/bin/clawworker
```

### Remove Data (Optional)

```bash
rm -rf ~/.clawworker
```

---

## How It Works

ClawWorker is distributed as a **single static binary** — no runtime dependencies, no Docker required, no package managers. The install script:

1. **Detects** your OS (Linux/macOS) and architecture (amd64/arm64)
2. **Downloads** the correct binary from GitHub Releases
3. **Verifies** the SHA256 checksum
4. **Installs** the binary to `/usr/local/bin`
5. **Registers** a system service (systemd on Linux, launchd on macOS)
6. **Starts** the service automatically

The service runs in `gateway` mode by default, which enables the Web UI, REST API, and any configured messaging channels.

---

## Docker Alternative

If you prefer containers:

```bash
docker run -d \
  --name clawworker \
  -p 8080:8080 \
  -e CLAWWORKER_PROVIDER=openai \
  -e CLAWWORKER_API_KEY=sk-... \
  -v clawworker-data:/root/.clawworker \
  ghcr.io/clawworker/clawworker:latest
```

---

## Security

- Binaries are **checksum-verified** during installation
- API keys are stored in an **encrypted vault** (`~/.clawworker/vault.enc`)
- Tool execution is controlled by **configurable policies**
- The install script runs with minimal privileges — `sudo` is only used to copy the binary to `/usr/local/bin`

---

## Troubleshooting

### Service won't start

ClawWorker needs at least one LLM provider configured:

```bash
clawworker onboard          # Interactive setup
clawworker doctor           # Run diagnostics
```

### Check logs

```bash
# Linux
journalctl --user -u clawworker -f

# macOS
tail -f ~/Library/Logs/clawworker/clawworker.log
```

### Verify installation

```bash
clawworker version
clawworker doctor
```

---

## Community & Support

- **Issues:** [GitHub Issues](https://github.com/clawworker/install/issues)
- **Discussions:** [GitHub Discussions](https://github.com/orgs/clawworker/discussions)

---

<p align="center">
  Built with care by <a href="https://codimite.com">Codimite</a>
</p>
<p align="center">
  Copyright &copy; 2026 ClawWorker. All Rights Reserved.
</p>
