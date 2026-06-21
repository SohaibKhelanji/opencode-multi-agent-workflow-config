Analyze this repository for the following engineering task:

$ARGUMENTS

Prompt handoff rules:
- First check whether `.opencode/tmp/prompt-handoff.md` exists.
- Check for the handoff without asking the user.
- If it exists, read it before doing repository analysis.
- Extract the refined analyzer prompt from it and use that refined prompt as the source of truth.
- Keep `.opencode/tmp/prompt-handoff.md` until final handoff cleanup.
- During final handoff cleanup, after `.opencode/tmp/analyzer-handoff.md` has been successfully written, delete `.opencode/tmp/prompt-handoff.md` without asking the user.
- If analysis stops before `.opencode/tmp/analyzer-handoff.md` is written, preserve `.opencode/tmp/prompt-handoff.md` for rerun.
- Use only the exact allowed temporary handoff deletion command for the current shell.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Confirm in your response whether the prompt handoff file was found, read, and deleted during final handoff cleanup or preserved for rerun.
- If the prompt handoff does not exist, use the arguments above as the analysis task.
- Do not assume hidden prompt-refinement context.
- Do not leave the prompt handoff file behind after the analyzer handoff has been successfully written.

Use specialized subagents by default for repository analysis:
- For repository analysis, use the `task` tool to delegate focused read-only exploration instead of doing every slice in the parent agent.
- For cross-area tasks, launch at least two relevant specialist subagents before writing the analyzer handoff.
- For narrow tasks, launch at least one relevant specialist subagent unless the task is purely about the OpenCode workflow/config or no repository context is needed.
- If the `task` tool is unavailable, blocked, or no specialist applies, record that explicitly in the normal analysis report and `.opencode/tmp/analyzer-handoff.md`.
- backend-analyzer for backend/API/database/auth/server concerns.
- frontend-analyzer for UI/client/forms/state/API-client concerns.
- docker-devops-analyzer for Docker, Compose, deployment, CI/CD, env, scripts, and runtime config.
- security-analyzer for vulnerabilities, authz/authn, validation, secrets, XSS, CSRF, SSRF, injection, CORS, cookies, and hardening.
- test-analyzer for tests, verification, lint/typecheck/build commands, fixtures, mocks, and coverage gaps.

Environment detection rules:
- Identify the host OS, project storage location, intended execution environment, and terminal later stages should use.
- Classify as Windows, Linux, macOS, WSL, WSL2, container/devcontainer, or unknown.
- Prefer evidence over guesses: path shape, shell type, path separators, `$OSTYPE`, `$WSL_DISTRO_NAME`, `/proc/version`, `uname`, Windows environment variables, Docker/devcontainer files, mount paths such as `/mnt/c`, UNC paths such as `\\wsl.localhost\...`, and command output when available.
- If evidence is mixed, distinguish host OS from project runtime.
- If the project is in WSL/WSL2, explicitly instruct `/brainstorm` and `/implement` to use WSL/Linux shell from the project root for repo commands and verification.
- If a tool such as `rg` appears unavailable in Windows PowerShell, do not mark it unavailable until it is checked inside the intended project runtime. Include this warning in the handoff.
- Include path conversion notes if later stages may run from Windows while the project lives in WSL.

WSL repository command prefix rules:
- Create a `WSL Repository Command Prefix` section when the project is stored or executed in WSL and later stages may run from Windows PowerShell.
- Every repository command must start with `wsl.exe -d <distro> --cd <repo-root>` using the canonical repository root from the Command Environment Contract.
- For the VLAM-Academy repo, every repository command must start with `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`.
- If a command must run in a package subdirectory, keep the WSL prefix at the repo root and change directory inside the command, such as `bash -lc "cd frontend && <command>"`.
- Do not run repository commands from Windows PowerShell directly when the contract says the repo runtime is WSL/Linux.
- Git completion commands still must invoke `git` directly through `wsl.exe` and must not use `bash -lc`.

Command environment contract rules:
- Create a `Command Environment Contract` that later stages must obey before running repository commands.
- Include intended terminal/runtime, canonical project root in that runtime, path style, shell syntax family, package manager, script runner, dependency setup commands, verification commands, and tool lookup commands.
- Include how to invoke the intended runtime from the current host when relevant. For WSL from Windows, include guidance like `wsl.exe -d <distro> --cd <linux-project-root> bash -lc '<command>'` when the distro and Linux project root can be determined.
- Explicitly warn against terminal syntax mismatch: do not use PowerShell syntax in WSL/Linux bash, do not use POSIX/bash syntax in PowerShell, and do not use Windows paths as shell paths unless the intended runtime accepts them.
- For every recommended command, include `Terminal`, `Working directory`, and `Command`.
- Define failure triage before declaring a command or tool unavailable: verify current shell, current working directory, path style, command syntax, and tool availability in the intended runtime.
- If a command fails with command not found, syntax errors, path errors, or tool-not-recognized errors, later stages must treat terminal mismatch as the first suspect and retry or check the equivalent command in the intended runtime before declaring a command or tool unavailable.

Git command safety rules:
- Create a `Git Command Safety` section that later stages must obey for staging, commit, and push.
- Run `git add` and `git commit` as separate commands.
- Do not combine `git add` and `git commit` with `&&`.
- Do not combine git completion steps with `&&`.
- For git status, git diff, git add, git commit, and git push in WSL from Windows, do not use `bash -lc`; invoke `git` directly through `wsl.exe`.
- Do not wrap `git commit -m` inside a nested `bash -lc` string when invoking WSL from Windows.
- Use direct invocation such as `wsl.exe -d <distro> --cd <repo-root> git add -- <paths>` and `wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'`.
- Treat commit messages with parentheses, quotes, ampersands, semicolons, dollar signs, backticks, or apostrophes as shell-quoting risks. Choose a clear quote-safe message when possible, or use a safer commit-message mechanism instead of embedding fragile text in a nested shell string.
- Use `git add -- <paths>` so path names cannot be interpreted as options.
- Before pushing, later stages must run `git remote -v`, `git status -sb`, and `git branch --show-current` as separate commands.
- Run a non-interactive remote/auth preflight before `git push`.
- For HTTPS or unknown remotes, use a preflight such as `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git ls-remote --exit-code origin HEAD` from the intended runtime.
- For SSH remotes, use a preflight such as `ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com` or the matching Git host/user from the remote URL.
- Push with non-interactive credential settings and porcelain output, such as `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git push --porcelain <remote> <branch>`.
- Set a bounded timeout for push commands when the tool supports timeouts, and treat timeout as auth/network blocked instead of retrying blindly.
- If push preflight fails or times out, report the exact remote, branch, preflight command, and failure mode instead of retrying `git push`.

Dependency and verification preflight rules:
- Create a `Dependency And Verification Preflight` that later stages must obey before lint, test, typecheck, or build commands.
- Detect package-manager and lockfile evidence, including `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `global.json`, `.nvmrc`, `.node-version`, `packages.lock.json`, or equivalent project files.
- Include Dependency setup commands with `Terminal`, `Working directory`, and `Command`.
- Canonical VLAM frontend verification commands:
  - If the project path is `/home/sk/projects/VLAM-Academy/frontend`, the repo path is `/home/sk/projects/VLAM-Academy`, or the package is `vlam-ai-leren`, record these exact commands as the canonical build and lint checks.
  - Build: `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run build 2>&1"`
  - Lint: `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run lint 2>&1"`
  - Do not substitute `npx eslint`, a different working directory, a different Node version, or a command that omits `source ~/.nvm/nvm.sh`.
  - These commands intentionally use `bash -lc` because NVM must be sourced before selecting Node `24.15.0`. This exception does not apply to git completion commands.
- Prefer reproducible setup commands when the project supports them, such as `npm ci`, `pnpm install --frozen-lockfile`, `yarn install --immutable`, `bun install --frozen-lockfile`, `dotnet restore`, or the repo's documented setup command.
- For Node projects, identify native optional dependency risk for packages such as lightningcss, @swc/core, sharp, esbuild, and Rollup optional native packages.
- For Node projects in POSIX runtimes, identify local package binary shim executable-bit risk for commands such as `node_modules/.bin/eslint`, `node_modules/.bin/next`, `node_modules/.bin/vitest`, `node_modules/.bin/jest`, and `node_modules/.bin/tsc`.
- If the project runs in WSL/Linux, dependency setup must run inside WSL/Linux with the selected Node version before verification; do not reuse a Windows-installed `node_modules`.
- If native `.node` files are missing, instruct later stages to repair dependencies in the intended runtime before treating the verification failure as an application code failure.
- If a local package executable exists but is not executable in WSL/Linux, instruct later stages to repair only package-manager bin shims with `chmod +x node_modules/.bin/<tool>` or a carefully scoped `chmod +x node_modules/.bin/*` before retrying the verification command.
- If dependency setup is blocked by network, lockfile, permission, or registry issues, tell later stages to report verification as environment-blocked with the exact setup blocker.

Return the normal analysis report in this structure:

# Analysis

## 1. Task Understanding
Restate the requested task. Classify it as one or more of: bug fix, security patch, feature, refactor, dependency upgrade, test repair, performance work, documentation, Docker/DevOps, or unknown.

## 2. Prompt Handoff Status
Say whether `.opencode/tmp/prompt-handoff.md` was found, read, and deleted. If it was not found, say that the direct command arguments were used.

## 3. Project Environment And Terminal Guidance
Classify host OS, project storage location, runtime environment, and the terminal later stages should use. Include evidence, confidence, path implications, and search-tool implications such as `rg` availability.

## 4. Command Environment Contract
Define the exact command contract later stages must follow:
- Intended terminal/runtime: <Windows PowerShell, WSL bash, Linux bash, macOS zsh, container shell, etc.>
- Canonical project root: <path in the intended runtime>
- Path style: <Windows, POSIX/Linux, UNC, container path, etc.>
- Shell syntax family: <PowerShell, POSIX bash/sh, zsh, cmd, etc.>
- Runtime invocation from current host: <for example `wsl.exe -d <distro> --cd <linux-project-root> bash -lc '<command>'`, or empty if not needed>
- Package manager and script runner: <npm/pnpm/yarn/bun/dotnet/cargo/etc. and how detected>
- Dependency setup commands: <Terminal + Working directory + Command for setup/restore/install in the intended runtime>
- Tool lookup commands: <for example `command -v rg` in bash or `Get-Command rg` in PowerShell>
- Command failure triage: <what to check before declaring a command unavailable>
- Command examples: <Terminal + Working directory + Command for search, tests, build, lint/typecheck>

## 5. WSL Repository Command Prefix
<when WSL applies, define the required `wsl.exe -d <distro> --cd <repo-root>` prefix for every repository command; for VLAM-Academy use `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`; explain package-subdirectory commands should use repo-root prefix plus `cd <package>` inside bash; state git completion uses direct `wsl.exe ... git` and not `bash -lc`>

## 6. Git Command Safety
Define the exact git command safety rules later stages must follow:
- Stage command: <Terminal + Working directory + Command; use git add -- <paths>>
- Commit command: <Terminal + Working directory + Command; use direct WSL git invocation where applicable and avoid bash -lc>
- Push command: <Terminal + Working directory + Command>
- WSL guidance: <use direct wsl.exe git invocation; do not use bash -lc for git completion from Windows>
- Shell quoting risks: <commit-message characters that need care, including parentheses and quotes>
- Command sequencing: <run git status, git diff, git add, git commit, and git push as separate commands with approval gates>
- Push preflight: <git remote -v, git status -sb, git branch --show-current, non-interactive ls-remote or SSH auth check, bounded timeout policy>

## 7. Dependency And Verification Preflight
Define the exact setup and verification readiness later stages must follow:
- Package manager and lockfile evidence: <files/scripts/runtime-version files checked>
- Dependency setup commands: <Terminal + Working directory + Command in the intended runtime>
- Canonical VLAM frontend verification commands: <if project matches `/home/sk/projects/VLAM-Academy/frontend`, `/home/sk/projects/VLAM-Academy`, or package `vlam-ai-leren`, include the exact build and lint commands from the rules above>
- Native optional dependency risk: <Node native packages such as lightningcss, @swc/core, sharp, esbuild, Rollup optional native packages, or none detected>
- Native dependency repair: <how to repair missing `.node` packages in the intended runtime before verification>
- Node bin shim executable-bit risk: <local package executables such as node_modules/.bin/eslint, next, vitest, jest, tsc, or none detected>
- Node bin shim repair: <carefully scoped chmod +x command for node_modules/.bin/<tool> or node_modules/.bin/* in POSIX runtimes only>
- Verification command order: <setup/restore before lint/test/typecheck/build>
- Environment-blocked conditions: <network, lockfile, registry, permission, or runtime blockers>

## 8. Subagent Work Performed
List which subagents were used or which slices were inspected. If a subagent was not used, briefly say why.

## 9. Repository Map
Summarize important directories and their responsibilities.

## 10. Existing Architecture
Explain the relevant architecture, runtime flow, data flow, API boundaries, persistence layer, auth/session handling, external services, Docker/deployment setup, build system, and test setup where applicable.

## 11. Relevant Files
List files most likely involved. For each file include path, area, why it matters, important functions/classes/components/routes/configs, and whether it likely needs reading, editing, or only awareness.

## 12. Cross-Area Impact
Explain how backend, frontend, Docker/DevOps, security, tests, and shared code may interact for this task.

## 13. Current Behavior And Current Pattern
Describe how the repo currently handles this kind of behavior and existing conventions that should be followed.

## 14. Risks And Unknowns
List risks, edge cases, security concerns, compatibility concerns, migrations, breaking changes, missing information, and environment-specific concerns.

## 15. Recommended Plan
Give a prioritized implementation plan. Include exact files likely to change. If the current architecture is part of the problem, clearly separate targeted fix, larger refactor, and architecture revamp options so `/brainstorm` can put those decisions in front of the user.

## 16. Verification Plan
List tests, lint/typecheck/build commands, manual checks, Docker/DevOps checks, security checks, and environment-specific commands. Include which terminal/runtime should run each command.

## 17. Context For Brainstormer
Create a compact but comprehensive section for `/brainstorm`.

Temporary analyzer handoff file:
- After producing the normal analysis report, create or overwrite `.opencode/tmp/analyzer-handoff.md`.
- Create `.opencode/tmp` if it does not exist.
- Final handoff cleanup: after `.opencode/tmp/analyzer-handoff.md` is successfully written, delete any consumed source handoff as the final cleanup step. Delete consumed handoff files only during final cleanup.
- You may check whether temporary handoff files exist without asking the user.
- If you must delete a temporary handoff or sprint-state file, delete only `.opencode/tmp/prompt-handoff.md`, `.opencode/tmp/analyzer-handoff.md`, `.opencode/tmp/brainstorm-handoff.md`, or `.opencode/tmp/sprint-backlog.md` and do not ask first.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Use the `write` tool to create or overwrite `.opencode/tmp/analyzer-handoff.md`.
- Never use `bash`, shell redirection, PowerShell commands, `cat`, `tee`, `echo`, Python, Node, `apply_patch`, `edit`, or any other workaround for handoff file writes.
- The handoff should be substantial enough for `/brainstorm` to use without the full chat history.
- Do not add a standalone section that repeats the user's initial request.
- Do not copy command boilerplate or slash-command workflow text into the handoff.
- Do not write full verbose analysis history to the handoff.

Write `.opencode/tmp/analyzer-handoff.md` using this structure:

# Analyzer Handoff

## Task
<task summary>

## Classification
<bug fix/security patch/feature/refactor/dependency upgrade/test repair/performance work/etc.>

## Project Environment And Terminal Guidance
<host OS, storage location, runtime, evidence, confidence, exact terminal guidance for later stages, path conversion notes, and whether to check tools such as rg inside WSL/Linux before falling back>

## Command Environment Contract
- Intended terminal/runtime: <Windows PowerShell, WSL bash, Linux bash, macOS zsh, container shell, etc.>
- Canonical project root: <path in intended runtime>
- Path style: <Windows, POSIX/Linux, UNC, container path, etc.>
- Shell syntax family: <PowerShell, POSIX bash/sh, zsh, cmd, etc.>
- Runtime invocation from current host: <for example `wsl.exe -d <distro> --cd <linux-project-root> bash -lc '<command>'`, or empty if not needed>
- Package manager and script runner: <npm/pnpm/yarn/bun/dotnet/cargo/etc. and how detected>
- Dependency setup commands: <Terminal + Working directory + Command for setup/restore/install in the intended runtime>
- Tool lookup commands: <for example `command -v rg` in bash or `Get-Command rg` in PowerShell>
- Command failure triage: <verify shell, cwd, path style, syntax, and intended-runtime availability before declaring a command unavailable>
- Command examples:
  - Terminal: <terminal/runtime>; Working directory: <path>; Command: <command>

## WSL Repository Command Prefix
<required WSL command prefix for repository commands when applicable; for VLAM-Academy use `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`; include package subdirectory guidance and git completion exception>

## Git Command Safety
<git staging, commit, and push guidance; include separate git status/diff/add/commit/push commands, direct WSL git invocation such as `wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'` when applicable, `git add -- <paths>`, non-interactive remote/auth preflight before push, non-interactive porcelain push, bounded push timeout policy, and a warning not to embed fragile commit messages inside nested `bash -lc` strings>

## Dependency And Verification Preflight
<package manager, lockfile evidence, Dependency setup commands, Canonical VLAM frontend verification commands when project evidence matches, native optional dependency notes including lightningcss where relevant, native `.node` repair guidance, Node bin shim executable-bit notes including node_modules/.bin/eslint where relevant, chmod +x repair guidance scoped to node_modules/.bin, verification command order, and environment-blocked setup risks>

## Relevant Files And Areas
- <path or area>: <why it matters, likely action, relevant functions/classes/routes/configs>

## Architecture Notes
<relevant architecture, data flow, runtime flow, ownership boundaries, and coupling>

## Current Behavior And Existing Patterns
<existing behavior and conventions to preserve or improve>

## Implementation Options For Brainstorming
<targeted fix, larger refactor, architecture revamp options when relevant, with trade-offs>

## Recommended Implementation Plan
<ordered plan with likely files and dependencies>

## Security / Risk Notes
<risks, edge cases, compatibility concerns, environment-specific concerns>

## Verification Plan
<tests, build, lint, typecheck, manual checks, security checks, exact terminal/runtime guidance, and Canonical VLAM frontend verification commands when applicable>

## Open Questions
<unknowns, assumptions, or empty if none>

Important:
- Do not write secrets or unnecessary sensitive content.
- Do not modify source files.
- The only file you may create or overwrite during analysis is `.opencode/tmp/analyzer-handoff.md`, and it must be written with the `write` tool.
