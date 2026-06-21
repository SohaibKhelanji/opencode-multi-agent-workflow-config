# OpenCode Multi-Agent Workflow Configuration

This repository contains my [OpenCode](https://opencode.ai) configuration for a structured multi-agent software engineering workflow.

## Pipeline

```
/prompt → /analyze → /brainstorm → /implement (or /sprint)
```

Each slash command delegates to a specialized agent and passes context via handoff files:

| Command | Agent | Purpose |
|---|---|---|
| `/prompt` | prompter | Clarifies rough requests into refined prompts |
| `/analyze` | repo-analyzer | Coordinates read-only analysis across 5 subagents |
| `/brainstorm` | brainstormer | Designs solutions and creates multi-sprint backlogs |
| `/implement` | implementor | Executes full plans with tests and verification |
| `/sprint` | sprint-implementor | Implements one sprint from a resumable backlog |

## Agents

- **5 primary agents** — prompter, repo-analyzer, brainstormer, implementor, sprint-implementor
- **5 read-only subagents** — backend-analyzer, frontend-analyzer, docker-devops-analyzer, security-analyzer, test-analyzer

## Key Features

- **Handoff-driven pipeline** — interruptible and resumable workflow via `.opencode/tmp/` handoff files
- **Environment-aware** — detects Windows/WSL and adapts commands accordingly
- **Safety-first** — read-only subagents enforce safe exploration; strict git discipline (no force-push, separate add/commit/push, non-interactive auth preflight)
- **Test-validated** — includes [workflow validation tests](./tests/validate-sprint-workflow.ps1)

## Requirements

- [OpenCode](https://opencode.ai) CLI
- PowerShell 5.1+ (for tests)

## Instalation 

To install this configuration, copy the repository contents into `%USERPROFILE%\.config\opencode` on Windows, preserving the existing folder structure, then restart OpenCode so it reloads `opencode.jsonc`, the agent definitions, commands, and supporting files.


