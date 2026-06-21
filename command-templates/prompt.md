Turn the following rough engineering request into a best-practice prompt for `/analyze`:

$ARGUMENTS

Prompt refinement rules:
- Do not implement code.
- Do not run repository analysis.
- Ask clarifying questions one at a time until you are sure what the user wants.
- Clarify the goal, scope, constraints, affected area, expected behavior, non-goals, edge cases, risk tolerance, and success criteria.
- Prefer multiple-choice questions when helpful, but allow open-ended answers.
- Preserve the user's intent and important wording, but do not copy the full initial request into the handoff.
- Make ambiguous requirements explicit.
- Separate confirmed requirements from assumptions and open questions.
- Ask for explicit user approval before writing the handoff file.

Approved prompt handoff:
- Only after the user explicitly approves the final refined prompt, create or overwrite `.opencode/tmp/prompt-handoff.md`.
- Create `.opencode/tmp` if it does not exist.
- Write a comprehensive but curated prompt handoff.
- You may check whether temporary handoff files exist without asking the user.
- If you must delete a temporary handoff or sprint-state file, delete only `.opencode/tmp/prompt-handoff.md`, `.opencode/tmp/analyzer-handoff.md`, `.opencode/tmp/brainstorm-handoff.md`, or `.opencode/tmp/sprint-backlog.md` and do not ask first.
- Never use `rm -f` in Windows PowerShell. PowerShell treats `rm` as `Remove-Item`, and `-f` is ambiguous.
- In Windows PowerShell, check temporary files with `Test-Path -LiteralPath '.opencode/tmp/<file>.md'` and delete them with `Remove-Item -LiteralPath '.opencode/tmp/<file>.md' -Force`.
- Use the `write` tool to create or overwrite `.opencode/tmp/prompt-handoff.md`.
- Never use `bash`, shell redirection, PowerShell commands, `cat`, `tee`, `echo`, Python, Node, `apply_patch`, `edit`, or any other workaround for handoff file writes.
- Do not add a standalone section that repeats the user's initial request.
- Do not copy command boilerplate, slash-command workflow text, or instructions from this template into the handoff.

Write `.opencode/tmp/prompt-handoff.md` using this structure:

# Prompt Handoff

## Refined Analyzer Prompt
<the final best-practice prompt that /analyze should use>

## Confirmed Goal
<the confirmed outcome the user wants>

## Scope And Non-Goals
<what is in scope and what should not be changed>

## Requirements And Constraints
<technical, product, architecture, security, performance, compatibility, style, or process constraints>

## Acceptance Criteria
<how success should be judged>

## Context To Preserve
<important user intent, terminology, examples, known project details, or assumptions to carry forward>

## Risks And Edge Cases
<risks, edge cases, sensitive areas, or things the analyzer should inspect carefully>

## Questions Resolved During Prompting
<short list of decisions already clarified with the user>

## Open Questions
<questions still unresolved, or empty if none>

Important:
- Do not write secrets or unnecessary sensitive content.
- Do not modify source files.
- The only file you may create or overwrite during prompt refinement is `.opencode/tmp/prompt-handoff.md`, and it must be written with the `write` tool.
