<p align="center">
  <img src="https://venice.ai/favicon.ico" width="60" alt="Venice.ai">
</p>

<h1 align="center">Venice.ai + Claude Code</h1>

<p align="center">
  <strong>Pseudonymous AI inference for privacy-focused development</strong>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://nodejs.org"><img src="https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg" alt="Node.js >= 18"></a>
  <a href="https://venice.ai/chat?ref=JiSk4J"><img src="https://img.shields.io/badge/Powered%20by-Venice.ai-purple.svg" alt="Venice.ai"></a>
</p>

<p align="center">
  Route Claude Code through Venice.ai for uncensored models, privacy-focused inference, and the ability to query multiple AI models from a single interface.
</p>

---

## Quick Start

### Prerequisites

| Requirement | Description |
|-------------|-------------|
| **Venice.ai API Key** | [Get your key](https://venice.ai/settings/api?ref=JiSk4J) |
| **Node.js 18+** | `node -v` to check |
| **jq** | `brew install jq` (macOS) / `apt install jq` (Linux) |
| **Claude Code** | [Download](https://claude.ai/download) |

> **Windows users:** Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or [Git Bash](https://gitforwindows.org/) to run the installer.

### Installation

> **Note:** Always clone the repository. Do not pipe install scripts from the internet into bash.

```bash
git clone https://github.com/mars-llm/claude-venice.git
cd claude-venice
./install.sh
```

The installer automatically installs and configures `claude-code-router` and detects existing [cc-mirror](https://github.com/numman-ali/cc-mirror) instances.

### Launch

```bash
code-venice
```

---

## CLI Tools

Run these commands in your terminal alongside Claude Code.

### `venice-ask` — Uncensored Queries & Model Access

Query Venice's uncensored model directly:

```bash
venice-ask "your question here"
venice-ask -i                      # Interactive chat mode
```

Or query specific models for different tasks:

```bash
venice-ask -m deepseek-r1-671b "explain quantum computing"
venice-ask -m qwen-2.5-coder-32b "write a python sort function"
venice-ask -m llama-3.3-70b "summarize this article"
```

### `venice-model` — List Available Models

```bash
venice-model list
```

### `venice-generate` — Create Media

```bash
# Video (async)
venice-generate video "a robot painting a sunset"
venice-generate status <job-id>

# Image
venice-generate image "cyberpunk cityscape at night"

# Audio
venice-generate audio "Hello world" --voice af_sky
venice-generate voices
```

> Output files saved to `~/venice-output/`

---

## Available Models

| Model | Best For |
|-------|----------|
| `deepseek-r1-671b` | Deep reasoning, mathematics |
| `qwen-2.5-coder-32b` | Code generation |
| `qwen3-235b` | Large context analysis |
| `llama-3.3-70b` | General purpose |
| `venice-uncensored` | Unrestricted queries |

---

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│ Claude Code │────▶│ claude-code-     │────▶│ Venice.ai   │
│             │     │ router :3456     │     │ API         │
└─────────────┘     └──────────────────┘     └─────────────┘
```

---

## Manual Setup

For vanilla Claude Code without the launcher:

```bash
# Start router
ccr start &

# Launch Claude Code
ANTHROPIC_BASE_URL=http://127.0.0.1:3456 claude
```

**Configuration:** `~/.claude-code-router/config-router.json` ([example](config/config-router.example.json))

---

## Troubleshooting

| Issue | Command |
|-------|---------|
| Check port usage | `lsof -i :3456` |
| Kill existing router | `pkill -f "ccr start"` |
| Health check | `curl http://127.0.0.1:3456/health` |

---

## Advanced: cc-mirror Integration

[cc-mirror](https://github.com/numman-ali/cc-mirror) enables multi-agent orchestration and team mode. The installer auto-detects cc-mirror instances—just create one before running the installer:

```bash
# Create cc-mirror instance first
npx cc-mirror quick --provider ccrouter --name venice

# Then run the installer as usual
./install.sh
```

---

## Credits

- [Venice.ai](https://venice.ai/chat?ref=JiSk4J) — Privacy-focused AI inference
- [claude-code-router](https://github.com/musistudio/claude-code-router) — Request routing
- [cc-mirror](https://github.com/numman-ali/cc-mirror) — Multi-agent orchestration

---

<p align="center">
  <sub>MIT License</sub>
</p>
