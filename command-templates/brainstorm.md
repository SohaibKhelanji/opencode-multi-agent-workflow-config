Brainstorm the following engineering task before implementation:

$ARGUMENTS

Analyzer handoff rules:
- First check whether `.opencode/tmp/analyzer-handoff.md` exists.
- Check for the handoff without asking the user.
- If it exists, read it before doing anything else.
- Extract the relevant implementation, design, environment, and terminal context into your working notes.
- Keep `.opencode/tmp/analyzer-handoff.md` until final handoff cleanup.
- During final handoff cleanup, after `.opencode/tmp/brainstorm-handoff.md` has been successfully written, delete `.opencode/tmp/analyzer-handoff.md` without asking the user.
- If brainstorming is canceled or stops before `.opencode/tmp/brainstorm-handoff.md` is written, preserve `.opencode/tmp/analyzer-handoff.md` for rerun.
- Use only the exact allowed temporary handoff deletion command for the current shell.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Confirm in your response whether the analyzer handoff file was read and deleted during final handoff cleanup or preserved for rerun.
- If the analyzer handoff does not exist, use any analyzer context pasted in this command.
- If neither a handoff nor pasted analyzer context exists and repository context is needed, ask the user to run `/analyze`.
- Do not assume access to hidden analyzer context.
- If analyzer context is missing, stale, contradictory, or too thin for a responsible plan, use the `task` tool to ask relevant read-only specialist subagents for focused follow-up context before presenting options.
- If specialist follow-up is skipped, explain why the existing analyzer context is sufficient.
- If the `task` tool is unavailable or blocked, say so and ask the user to rerun `/analyze` when repository context is needed.
- Do not leave the analyzer handoff file behind after the brainstorm handoff has been successfully written.

Brainstorming rules:
- Do not implement code.
- Do not edit source files.
- Keep the user in the driver seat for key decisions.
- Ask clarifying questions one at a time.
- Keep asking questions until you are sure you understand the user's goal, constraints, success criteria, and preferences.
- Prefer multiple-choice questions when helpful, but allow open-ended answers.
- Explore two or three implementation approaches with trade-offs and your recommendation.
- If the current architecture appears weak, ask whether the user wants a targeted fix, a larger refactor, or a full architecture revamp before implementation.
- Use DeepSeek V4 Flash's reasoning strength to design the full solution, then divide implementation into an ordered multi-sprint backlog so `/sprint` can implement one reviewable sprint at a time.
- Every approved brainstorm handoff must include a multi-sprint backlog with at least two sprints.
- Never write a one-sprint backlog. If the task is small, split it into at least two manageable sprints such as core change first, then tests/verification/docs/review cleanup.
- Preserve and carry forward the analyzer's project environment and terminal guidance.
- Preserve and carry forward the analyzer's `Command Environment Contract`.
- Preserve and carry forward the analyzer's `WSL Repository Command Prefix`.
- Preserve and carry forward the analyzer's `Git Command Safety`.
- Preserve and carry forward the analyzer's `Dependency And Verification Preflight`.
- If the analyzer handoff lacks a `Command Environment Contract`, mark the command environment as unknown and require `/implement` or `/sprint` to detect it before running repository commands.
- If the analyzer identified WSL/WSL2 as the project runtime, instruct the implementor to use WSL/Linux shell for repo commands and verification.
- If the analyzer identified a WSL repository command prefix, every sprint verification and repository command must use that `wsl.exe -d <distro> --cd <repo-root>` prefix.
- Do not mark `rg` or other tools unavailable unless they were checked inside the intended runtime.
- Carry forward Dependency setup commands, Canonical VLAM frontend verification commands, lockfile evidence, native optional dependency risks such as lightningcss, local package binary shim risks such as `node_modules/.bin/eslint`, repair guidance for missing `.node` packages, and scoped `chmod +x` guidance for non-executable `node_modules/.bin` shims in POSIX runtimes.
- If the project path is `/home/sk/projects/VLAM-Academy/frontend`, the repo path is `/home/sk/projects/VLAM-Academy`, or the package is `vlam-ai-leren`, every sprint that needs build or lint verification must use the exact canonical VLAM build and lint commands from the analyzer handoff.
- Carry forward safe git staging, commit, and push commands. Run each git completion step as a separate command. Do not combine git completion steps with `&&`. For git status, git diff, git add, git commit, and git push in WSL from Windows, do not use `bash -lc`; invoke `git` directly through `wsl.exe`. Do not wrap `git commit -m` inside a nested `bash -lc` string when invoking WSL from Windows. Include a non-interactive remote/auth preflight before `git push` and a bounded push timeout policy.
- Present the design in sections covering architecture, components, data flow, error handling, testing, risks, and rollout.
- Before writing the handoff, present a complete proposed implementation plan, a `Sprint Backlog For /sprint`, and a predefined implementor subagent slice map.
- Each slice must include the slice name, purpose, likely files or areas, expected output, dependencies, and when the implementor should run it.
- Each sprint must include goal, user story, success criteria, scope, dependencies, likely files or areas, subagent slices, tests, dependency preflight, verification commands, and Commit-message guidance.
- Each sprint must concentrate on a single feature, one point of a feature, one integration boundary, one test/verification slice, or one cleanup/review slice.
- Keep sprints small enough that the implementor can fully understand, implement, test, verify, commit, and push that sprint without needing to reason about the entire plan.
- Each sprint must be small enough for `/sprint` to implement, verify, commit, and push in one run.
- Use the question tool for the approval gate with choices: approve plan and write handoff, revise plan, or cancel brainstorming.
- If the user chooses revise plan, ask what should change, update the plan and slice map, then ask the approval question again.
- If the user chooses cancel, do not write the brainstorm handoff.

Approved brainstorm handoff:
- Only after the user explicitly approves the design through the question tool, create or overwrite `.opencode/tmp/brainstorm-handoff.md`.
- Create `.opencode/tmp` if it does not exist.
- Final handoff cleanup: after `.opencode/tmp/brainstorm-handoff.md` is successfully written, delete any consumed source handoff as the final cleanup step. Delete consumed handoff files only during final cleanup.
- You may check whether temporary handoff files exist without asking the user.
- If you must delete a temporary handoff or sprint-state file, delete only `.opencode/tmp/prompt-handoff.md`, `.opencode/tmp/analyzer-handoff.md`, `.opencode/tmp/brainstorm-handoff.md`, or `.opencode/tmp/sprint-backlog.md` and do not ask first.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Use the `write` tool to create or overwrite `.opencode/tmp/brainstorm-handoff.md`.
- Never use `bash`, shell redirection, PowerShell commands, `cat`, `tee`, `echo`, Python, Node, `apply_patch`, `edit`, or any other workaround for handoff file writes.
- The handoff should be comprehensive enough for `/implement` to proceed without chat history.
- Do not add a standalone section that repeats the user's initial request.
- Do not copy command boilerplate or slash-command workflow text into the handoff.
- Do not write full verbose brainstorming history to the handoff.

Write `.opencode/tmp/brainstorm-handoff.md` using this structure:

# Brainstorm Handoff

## Task
<approved task summary>

## User Decisions
- <key decision and chosen option>

## Approved Architecture Direction
<approved architecture, refactor, or revamp direction>

## Scope And Non-Goals
<what is in scope and out of scope>

## Project Environment And Terminal Guidance
<carry forward host/runtime/storage evidence, terminal to use, path notes, and rg/tooling guidance>

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
<carry forward the required `wsl.exe -d <distro> --cd <repo-root>` prefix for repository commands when applicable; for VLAM-Academy use `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`; explain package subdirectory commands use repo-root prefix plus `cd <package>` inside bash; git completion remains direct `wsl.exe ... git`>

## Git Command Safety
<carry forward safe git status/diff/add/commit/push commands, approval gates, `git add -- <paths>`, direct WSL git invocation such as `wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'` when applicable, hard warning not to use `bash -lc` for WSL git completion, non-interactive remote/auth preflight such as `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git ls-remote --exit-code origin HEAD` or `ssh -T -o BatchMode=yes -o ConnectTimeout=10`, non-interactive porcelain push such as `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git push --porcelain <remote> <branch>`, bounded push timeout policy, and warning not to embed fragile commit messages inside nested shell strings>

## Dependency And Verification Preflight
<carry forward package-manager and lockfile evidence, Dependency setup commands, Canonical VLAM frontend verification commands when applicable, native optional dependency risks such as lightningcss, local package binary shim risks such as node_modules/.bin/eslint, repair guidance for missing `.node` packages, scoped chmod +x guidance for non-executable node_modules/.bin shims in POSIX runtimes, setup-before-verification order, and environment-blocked setup risks>

## Relevant Files / Areas
- <path or area>: <expected action and why it matters>

## Implementation Standards
<strict style, typing, comments, boundaries, and test expectations>

## Implementation Slices For Subagents
### <slice name>
- Specialty: <architecture/backend/frontend/docker-devops/security/tests/file-inspection/review/git-completion/etc.>
- Purpose: <why this slice exists>
- Likely files or areas: <paths or areas>
- Expected output: <what the implementor should ask this subagent to return>
- Dependencies: <other slices or decisions this depends on>
- Timing: <before edits/during edits/after edits/final review>

## Sprint Backlog For /sprint
- Backlog type: multi-sprint
- Minimum sprint count: at least 2
- Sprint state file: `.opencode/tmp/sprint-backlog.md`

### Sprint 1: <name>
- Status: pending
- Goal: <specific sprint outcome>
- User story: <as a user/developer/operator, I want..., so that...>
- Success criteria: <observable acceptance criteria>
- Scope: <what this sprint may change>
- Non-goals: <what this sprint must not change>
- Dependencies: <prior sprints, decisions, or project state required>
- Likely files or areas: <paths or areas>
- Subagent slices: <approved slices to use inside this sprint>
- Tests: <tests to add or update in this sprint>
- Dependency preflight: <setup/restore/install command that must run before lint, test, typecheck, or build; include native optional dependency repair and node_modules/.bin/eslint executable-bit repair if relevant>
- Verification commands: <Terminal + Working directory + Command using the Command Environment Contract and WSL Repository Command Prefix; use Canonical VLAM frontend verification commands exactly when applicable>
- Commit-message guidance: <scoped commit message suggestion>
- Git command safety: <safe status/diff/add/commit/push command pattern using separate direct WSL git commands, no bash -lc, quote-safe commit message invocation, non-interactive push preflight, and bounded push timeout policy>

### Sprint 2: <name>
- Status: pending
- Goal: <specific sprint outcome>
- User story: <as a user/developer/operator, I want..., so that...>
- Success criteria: <observable acceptance criteria>
- Scope: <what this sprint may change>
- Non-goals: <what this sprint must not change>
- Dependencies: <prior sprints, decisions, or project state required>
- Likely files or areas: <paths or areas>
- Subagent slices: <approved slices to use inside this sprint>
- Tests: <tests to add or update in this sprint>
- Dependency preflight: <setup/restore/install command that must run before lint, test, typecheck, or build; include native optional dependency repair and node_modules/.bin/eslint executable-bit repair if relevant>
- Verification commands: <Terminal + Working directory + Command using the Command Environment Contract and WSL Repository Command Prefix; use Canonical VLAM frontend verification commands exactly when applicable>
- Commit-message guidance: <scoped commit message suggestion>
- Git command safety: <safe status/diff/add/commit/push command pattern using separate direct WSL git commands, no bash -lc, quote-safe commit message invocation, non-interactive push preflight, and bounded push timeout policy>

## Recommended Subagent Assignment Order
<ordered list of slices the implementor should delegate or perform>

## Implementation Plan
<ordered plan approved by the user>

## Test And Verification Plan
<tests to add or update, verification commands, exact Terminal + Working directory + Command guidance from the Command Environment Contract, and Canonical VLAM frontend verification commands when applicable>

## Risks / Rollback / Follow-up
<remaining risks, rollback considerations, assumptions, or follow-up work>

## Open Questions For Implementor
<questions still unresolved, or empty if none>

Important:
- Do not write secrets or unnecessary sensitive content.
- Do not modify source files.
- The only file you may create or overwrite during brainstorming is `.opencode/tmp/brainstorm-handoff.md`, and it must be written with the `write` tool.
