Implement exactly one approved sprint from the sprint backlog:

$ARGUMENTS

Required workflow gate:
- First check whether `.opencode/tmp/sprint-backlog.md` exists.
- Check for the sprint backlog without asking the user.
- If `.opencode/tmp/sprint-backlog.md` exists, read it before doing anything else.
- If `.opencode/tmp/sprint-backlog.md` does not exist, check whether `.opencode/tmp/brainstorm-handoff.md` exists without asking the user.
- If neither `.opencode/tmp/sprint-backlog.md` nor `.opencode/tmp/brainstorm-handoff.md` exists, stop and tell the user to run `/brainstorm` first.
- If `.opencode/tmp/brainstorm-handoff.md` exists, read it before source inspection.
- Extract only the approved `Sprint Backlog For /sprint`, project environment and terminal guidance, implementation standards, test expectations, risks, and approved sprint subagent slices.
- If the brainstorm handoff does not include `Sprint Backlog For /sprint`, stop and ask the user to rerun `/brainstorm` so a sprint backlog can be approved.
- Seed `.opencode/tmp/sprint-backlog.md` from the approved sprint backlog before implementation begins.
- Use the `write` tool to create or overwrite `.opencode/tmp/sprint-backlog.md`.
- Keep `.opencode/tmp/brainstorm-handoff.md` until final handoff cleanup.
- During final handoff cleanup, after `.opencode/tmp/sprint-backlog.md` has been successfully written and the selected sprint run reaches its final cleanup point, delete `.opencode/tmp/brainstorm-handoff.md` without asking the user.
- If `/sprint` stops before `.opencode/tmp/sprint-backlog.md` is written, preserve `.opencode/tmp/brainstorm-handoff.md` for rerun.
- Use only the exact allowed temporary handoff deletion command for the current shell.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Confirm in your response whether the backlog was loaded from `.opencode/tmp/sprint-backlog.md` or seeded from `.opencode/tmp/brainstorm-handoff.md`.
- Do not assume access to hidden analyzer or brainstorm context.
- Do not inspect or edit source files until a selected sprint is approved.

One-sprint rule:
- Select only the first pending or in-progress sprint from `.opencode/tmp/sprint-backlog.md`.
- If one sprint is in-progress, continue that sprint.
- If no sprint is in-progress, select the first pending sprint.
- If all sprints are complete, delete `.opencode/tmp/sprint-backlog.md`, report that the approved backlog is complete, and stop without editing.
- If the user asks you to do all remaining sprints, refuse full-backlog implementation and explain that `/sprint` only performs one approved sprint per run.
- Do not merge multiple pending sprints into one run.
- Do not pull future-sprint work forward unless the backlog explicitly marks it as a dependency of the selected sprint.
- Use the question tool to ask for approval before starting the selected sprint.
- If the user does not approve the selected sprint, do not inspect or edit source files.

Selected sprint briefing:
- Restate the selected sprint goal, user story, acceptance criteria, scope, non-goals, dependencies, likely files or areas, approved subagent slices, tests, verification commands, and commit-message guidance.
- Restate the `Command Environment Contract`: intended terminal/runtime, canonical project root, path style, shell syntax family, runtime invocation, package manager/script runner, tool lookup commands, and failure triage.
- Restate the `Git Command Safety`: separate git status/diff/add/commit/push commands, safe staging with `git add -- <paths>`, quote-safe commit message invocation, direct WSL git invocation when applicable, and commit/push approval gates.
- Restate the selected sprint's dependency preflight: setup command, lockfile evidence, native optional dependency risks, native `.node` repair guidance, and local Node package bin shim executable-bit repair guidance.
- Identify unresolved sprint questions or risky assumptions before source inspection.
- If unresolved sprint questions affect behavior, architecture, security, data shape, tests, or public interfaces, stop and ask the user.

Subagent and implementation rules:
- Use the selected sprint's approved subagent slices as the delegation map.
- Delegate or perform slices in dependency order.
- Each subagent slice must stay inside the current sprint scope and return focused findings or implementation guidance.
- Inspect relevant files before editing.
- List files intended for editing before changing them.
- Make the current sprint changes required for correctness, maintainability, security, and testability.
- Stay inside approved sprint scope and avoid unrelated refactors.
- Follow existing project conventions unless the sprint backlog says the existing convention is part of the problem.
- Do not add dependencies unless clearly necessary for the current sprint or explicitly approved.
- Apply strict cross-language engineering standards: small cohesive files, target about 200 lines per file and avoid files over 300 lines, SOLID, DRY, KISS, YAGNI, explicit dependencies, clear boundaries, strong naming, strict typing, no `var`, no casual `any`, explicit public/exported contracts, secure validation and authorization at boundaries, and separation of domain/application behavior from infrastructure where applicable.
- Always add comments required by the repository style. When no style exists, add concise documentation comments for public/exported APIs and short intent comments for non-obvious internal/private functions.
- Every sprint must add or update test cases. If tests truly cannot be added or updated, stop and ask the user before proceeding.

Verification rules:
- Run the selected sprint's verification commands when possible.
- Follow the `Command Environment Contract` from the sprint backlog.
- Do not run a repository command until you have matched the command syntax to the intended terminal, working directory, and path style from the command contract.
- If the command contract is missing or ambiguous, inspect the environment first and establish the intended terminal/runtime before running repository commands.
- If the project is stored or executed in WSL/WSL2, use WSL/Linux shell from the project root for repo commands and verification whenever possible.
- If the current tool shell is not the intended runtime, invoke the intended runtime explicitly when possible, such as `wsl.exe -d <distro> --cd <linux-project-root> bash -lc '<command>'` for WSL from Windows.
- For git status, diff, add, commit, and push, the `Git completion rules` below override this generic WSL `bash -lc` example.
- Every repository command for the VLAM-Academy repo must start with `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`.
- If a VLAM command must run in the frontend package, keep `--cd /home/sk/projects/VLAM-Academy` and use `bash -lc "cd frontend && <command>"`.
- Do not claim `rg` is unavailable because Windows PowerShell cannot find it. Check inside the intended runtime first, or explain that the intended runtime check could not be performed.
- If a command fails with command not found, syntax errors, path errors, or tool-not-recognized errors, treat terminal mismatch as the first suspect.
- Before declaring a command unavailable or broken, verify current shell, current working directory, path style, syntax family, and tool availability with the lookup command from the command contract.
- Run the equivalent command in the intended runtime before declaring failure.
- Never mix PowerShell syntax into WSL/Linux bash, POSIX/bash syntax into PowerShell, or Windows paths into POSIX commands unless the command contract explicitly says that is supported.
- Run dependency setup in the intended runtime before lint, test, typecheck, or build commands.
- Use the package manager, lockfile, runtime version, and setup command from the sprint backlog; prefer reproducible setup commands such as `npm ci`, `pnpm install --frozen-lockfile`, `yarn install --immutable`, `bun install --frozen-lockfile`, `dotnet restore`, or the repo's documented setup command.
- Canonical VLAM frontend verification commands:
  - If the project path is `/home/sk/projects/VLAM-Academy/frontend`, the repo path is `/home/sk/projects/VLAM-Academy`, or the package is `vlam-ai-leren`, use these exact commands for build and lint checks.
  - Build: `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run build 2>&1"`
  - Lint: `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run lint 2>&1"`
  - Do not substitute `npx eslint`, a different working directory, a different Node version, or a command that omits `source ~/.nvm/nvm.sh`.
  - If a previous sprint backlog or brainstorm handoff lacks these canonical VLAM commands, follow this prompt/template over the stale handoff.
  - These commands intentionally use `bash -lc` because NVM must be sourced before selecting Node `24.15.0`. This exception does not apply to git completion commands.
- For Node projects in WSL/Linux, run dependency setup and verification in WSL/Linux with the selected Node version. Do not use Windows-installed `node_modules` for Linux verification.
- If a Node.js verification command fails because a native optional dependency is missing, such as lightningcss, @swc/core, sharp, esbuild, or a Rollup optional native package, treat it as a dependency setup mismatch first.
- Repair by running the dependency install or clean install command in the intended runtime. If native optional dependencies are still missing, inspect package-manager config for optional dependency omission, platform, architecture, registry, and lockfile issues before rerunning setup.
- Do not treat missing native optional packages as application code failures until dependency setup has been repaired in the intended runtime.
- Before running Node package executables in POSIX runtimes, verify local package binary shims are executable.
- If a local package binary shim exists but is not executable, such as `node_modules/.bin/eslint`, repair only package-manager bin shims with `chmod +x node_modules/.bin/<tool>` or a carefully scoped `chmod +x node_modules/.bin/*`, then retry the verification command.
- Treat `Permission denied`, missing executable bits, or `spawn EACCES` from `node_modules/.bin` as dependency setup/runtime-state issues first, not application code failures.
- If network, registry, lockfile, or permission constraints block dependency setup, report verification as environment-blocked with the exact setup blocker instead of claiming the application failed lint, tests, typecheck, or build.
- If verification fails, fix within the current sprint scope or stop and report the blocker.

Backlog update rules:
- After completing the sprint, rewrite `.opencode/tmp/sprint-backlog.md` with the selected sprint status, changed files, tests added or updated, verification commands and results, commit status, push status, remaining risks, and all remaining sprints.
- Use the `write` tool to create or overwrite `.opencode/tmp/sprint-backlog.md`.
- Never use `bash`, shell redirection, PowerShell commands, `cat`, `tee`, `echo`, Python, Node, `apply_patch`, `edit`, or any other workaround for sprint-state writes.
- Use `write` only for `.opencode/tmp` handoff or sprint-state files.
- Do not use `write` for source, test, config, or documentation implementation edits; use `edit` or `apply_patch` for those so normal edit approval applies.
- Mark exactly the selected sprint complete unless implementation stopped or verification failed.
- Leave future sprints pending unless the user explicitly cancels or revises the backlog.
- If all sprints are complete, delete `.opencode/tmp/sprint-backlog.md` after recording the final completion status in your response.
- Do not leave consumed brainstorm handoffs behind after the sprint backlog has been successfully written and the selected sprint run reaches final cleanup.

Git completion rules:
- Treat commit and push as part of each sprint completion when the project is a git repository.
- Before committing, inspect `git status` and `git diff` after edits and verification.
- Stage only intended source, test, config, or doc changes from the current sprint.
- Never stage `.opencode/tmp/`, analyzer handoffs, brainstorm handoffs, prompt handoffs, sprint backlog files, secrets, local env files, or unrelated user changes.
- Do not commit until relevant verification has passed unless the user explicitly approves a WIP commit.
- Use the sprint's commit-message guidance when it fits the actual diff; otherwise use a clear scoped commit message.
- If a previous sprint backlog or brainstorm handoff lacks `Git Command Safety`, follow this prompt/template over the stale handoff.
- For git status, git diff, git add, git commit, and git push in WSL from Windows, do not use `bash -lc`; invoke `git` directly through `wsl.exe`.
- Run `git status`, `git diff`, `git add`, `git diff --cached --stat`, `git commit`, and `git push` as separate commands.
- Run `git add` and `git commit` as separate commands.
- Do not combine `git add` and `git commit` with `&&`.
- Do not combine git completion steps with `&&`.
- Use `git add -- <paths>` when staging specific files.
- Do not wrap `git commit -m` inside a nested `bash -lc` string when invoking WSL from Windows.
- When invoking WSL from Windows for git commands, prefer direct WSL git invocation when no shell setup is required, such as `wsl.exe -d <distro> --cd <repo-root> git add -- <paths>` and `wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'`.
- Forbidden example: `wsl.exe -d <distro> --cd <repo-root> bash -lc 'git add <paths> && git diff --cached --stat && git commit -m "<message>"'`.
- Correct first attempt:
  - `wsl.exe -d <distro> --cd <repo-root> git add -- <paths>`
  - `wsl.exe -d <distro> --cd <repo-root> git diff --cached --stat`
  - `wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'`
- Treat commit messages containing parentheses, quotes, ampersands, semicolons, dollar signs, backticks, or apostrophes as shell-quoting risks; choose a clear quote-safe message or use a safer commit-message mechanism rather than embedding fragile text inside nested shell strings.
- Use the question tool to ask the user for approval before creating the sprint commit.
- After committing, use the question tool to ask the user for approval before pushing.
- Before pushing, run `git remote -v`, `git status -sb`, and `git branch --show-current` as separate commands.
- Run a non-interactive remote/auth preflight before `git push`.
- For HTTPS or unknown remotes, use `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git ls-remote --exit-code origin HEAD` before push.
- For SSH remotes, verify non-interactive SSH auth with `ssh -T -o BatchMode=yes -o ConnectTimeout=10` against the remote host/user before push.
- Push with non-interactive credential settings and porcelain output: `env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git push --porcelain <remote> <branch>`.
- Set a bounded timeout for push commands when the tool supports timeouts, and treat timeout as auth/network blocked instead of retrying blindly.
- If push preflight fails or times out, report the exact remote, branch, preflight command, and failure mode instead of retrying `git push`.
- Push only to the current intended branch/remote when it is clear.
- Never force-push unless the user explicitly requests it and you explain the risk.
- If the directory is not a git repository, or no remote is configured, report that commit or push was skipped and why.

Final report:
- Whether the backlog was loaded from `.opencode/tmp/sprint-backlog.md` or seeded from `.opencode/tmp/brainstorm-handoff.md`.
- Whether the brainstorm handoff file was deleted during final handoff cleanup or preserved for rerun.
- Selected sprint name, status, and acceptance criteria result.
- Predefined sprint subagent slices used.
- Slices merged, skipped, or performed directly, with reasons.
- Changed files.
- What changed and why.
- Tests added or edited.
- Verification commands run, terminal/runtime used, and results.
- Commit hash or commit status.
- Push status.
- Whether `.opencode/tmp/sprint-backlog.md` was rewritten or deleted.
- Remaining sprints, risks, or follow-up work.

Important:
- Do not write secrets or unnecessary sensitive content.
- Do not implement more than one sprint in this run.
- Do not modify future sprint scope unless the user explicitly revises the backlog.
