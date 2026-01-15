---
name: venice
description: Use this skill when the user wants to query a specific AI model, generate media (video/image/audio), or ask uncensored questions. Trigger phrases include "ask deepseek", "ask qwen", "ask llama", "generate video", "generate image", "create audio", "uncensored", or model names.
---

# Venice.ai Tools

Execute these commands directly when the user requests model queries, media generation, or uncensored queries.

## Query Specific Models

Use `venice-ask -m <model>` to send a question to a specific Venice model:

```bash
venice-ask -m deepseek-r1-671b "your question"
venice-ask -m qwen-2.5-coder-32b "your question"
venice-ask -m llama-3.3-70b "your question"
venice-ask "your question"  # Uses venice-uncensored by default
```

**Available models:**
| Model ID | Best For |
|----------|----------|
| `deepseek-r1-671b` | Deep reasoning, math |
| `qwen-2.5-coder-32b` | Code generation |
| `qwen3-235b` | Large context |
| `llama-3.3-70b` | General purpose |
| `venice-uncensored` | Unrestricted queries (default) |

**Action required:** When user says "ask deepseek about X" or "use qwen to answer Y", run:
```bash
venice-ask -m deepseek-r1-671b "X"
```

## Media Generation

**Video (async - returns job ID):**
```bash
venice-generate video "description of video"
venice-generate status <job-id>  # Check progress and download
```

**Image (instant):**
```bash
venice-generate image "description of image"
```

**Audio/Speech:**
```bash
venice-generate audio "text to speak" --voice af_sky
venice-generate voices  # List available voices
```

Output files are saved to `~/venice-output/`

## Instructions

1. **Execute commands directly** - Don't just show commands, run them
2. **Show output** - Display command results to the user
3. **Video is async** - Tell user the job ID and explain they can check status later
