Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root 'opencode.jsonc'

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    throw "FAILED: $Message"
  }
}

function Assert-Equal {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Message
  )

  if ($Actual -ne $Expected) {
    throw "FAILED: $Message. Expected '$Expected', got '$Actual'."
  }
}

function Assert-Contains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Message
  )

  Assert-True -Condition $Text.Contains($Needle) -Message $Message
}

function Assert-NotContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Message
  )

  Assert-True -Condition (-not $Text.Contains($Needle)) -Message $Message
}

function Get-JsoncObject {
  param([string]$Path)

  $rawContent = Get-Content -Raw -LiteralPath $Path
  $jsonContent = [regex]::Replace($rawContent, '(?m)^\s*//.*\r?\n?', '')
  return $jsonContent | ConvertFrom-Json
}

function Get-ObjectPropertyValue {
  param(
    [object]$InputObject,
    [string]$PropertyName
  )

  $property = $InputObject.PSObject.Properties[$PropertyName]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Assert-FileReferenceExists {
  param(
    [string]$RawConfig,
    [string]$RootPath
  )

  $matches = [regex]::Matches($RawConfig, '\{file:([^}]+)\}')
  foreach ($match in $matches) {
    $relativePath = $match.Groups[1].Value
    $absolutePath = Join-Path $RootPath $relativePath
    Assert-True -Condition (Test-Path -LiteralPath $absolutePath) -Message "file reference exists: $relativePath"
  }
}

function Assert-HandoffAllowlist {
  param(
    [object]$Agent,
    [string]$AgentName
  )

  $bashPermission = $Agent.permission.bash
  Assert-True -Condition ($bashPermission -isnot [string]) -Message "$AgentName has object bash permission allowlist"
  Assert-Equal -Actual $bashPermission.'*' -Expected 'ask' -Message "$AgentName keeps bash default as ask"

  $temporaryFiles = @(
    'prompt-handoff.md',
    'analyzer-handoff.md',
    'brainstorm-handoff.md',
    'sprint-backlog.md'
  )

  foreach ($fileName in $temporaryFiles) {
    $relativeFilePath = ".opencode/tmp/$fileName"
    $powerShellFilePath = ".opencode/tmp/$fileName"

    $posixTestPermission = Get-ObjectPropertyValue -InputObject $bashPermission -PropertyName "test -f $relativeFilePath"
    $posixRemovePermission = Get-ObjectPropertyValue -InputObject $bashPermission -PropertyName "rm -f $relativeFilePath"

    Assert-True -Condition ($null -eq $posixTestPermission) -Message "$AgentName does not auto-allow POSIX test for $fileName in Windows control shell"
    Assert-True -Condition ($null -eq $posixRemovePermission) -Message "$AgentName does not auto-allow POSIX rm for $fileName in Windows control shell"
    Assert-Equal -Actual $bashPermission."Test-Path -LiteralPath '$powerShellFilePath'" -Expected 'allow' -Message "$AgentName can check $fileName with PowerShell"
    Assert-Equal -Actual $bashPermission."Remove-Item -LiteralPath '$powerShellFilePath' -Force" -Expected 'allow' -Message "$AgentName can delete $fileName with PowerShell"
  }
}

function Assert-NoStandaloneWritePermission {
  param(
    [object]$Agent,
    [string]$AgentName
  )

  $writePermission = Get-ObjectPropertyValue -InputObject $Agent.permission -PropertyName 'write'
  $applyPatchPermission = Get-ObjectPropertyValue -InputObject $Agent.permission -PropertyName 'apply_patch'

  Assert-True -Condition ($null -eq $writePermission) -Message "$AgentName does not use unsupported permission.write"
  Assert-True -Condition ($null -eq $applyPatchPermission) -Message "$AgentName does not use unsupported permission.apply_patch"
}

function Assert-NoWriteToolPattern {
  param(
    [object]$EditPermission,
    [string]$AgentName
  )

  $writeToolPattern = Get-ObjectPropertyValue -InputObject $EditPermission -PropertyName 'write'
  Assert-True -Condition ($null -eq $writeToolPattern) -Message "$AgentName does not use invalid edit.write tool-name pattern"
}

function Assert-ReadOnlyAnalysisTaskAllowlist {
  param(
    [object]$Agent,
    [string]$AgentName
  )

  $taskPermission = $Agent.permission.task
  Assert-True -Condition ($taskPermission -isnot [string]) -Message "$AgentName uses explicit task allowlist"
  Assert-Equal -Actual $taskPermission.'*' -Expected 'deny' -Message "$AgentName denies unspecified subagents"

  foreach ($subagentName in @(
    'backend-analyzer',
    'frontend-analyzer',
    'docker-devops-analyzer',
    'security-analyzer',
    'test-analyzer'
  )) {
    Assert-Equal -Actual (Get-ObjectPropertyValue -InputObject $taskPermission -PropertyName $subagentName) -Expected 'allow' -Message "$AgentName can delegate to $subagentName"
  }
}

function Assert-WriteOnlyEditPermission {
  param(
    [object]$Agent,
    [string]$AgentName
  )

  $editPermission = $Agent.permission.edit
  Assert-True -Condition ($editPermission -isnot [string]) -Message "$AgentName uses documented permission.edit object for write tool access"
  Assert-Equal -Actual $editPermission.'*' -Expected 'deny' -Message "$AgentName denies edit/apply_patch by default"
  Assert-Equal -Actual $editPermission.'.opencode/tmp/*' -Expected 'allow' -Message "$AgentName allows file modifications only for temporary handoff state"
  Assert-NoWriteToolPattern -EditPermission $editPermission -AgentName $AgentName
  Assert-NoStandaloneWritePermission -Agent $Agent -AgentName $AgentName
}

function Assert-ImplementationEditPermission {
  param(
    [object]$Agent,
    [string]$AgentName
  )

  $editPermission = $Agent.permission.edit
  Assert-True -Condition ($editPermission -isnot [string]) -Message "$AgentName uses documented permission.edit object"
  Assert-Equal -Actual $editPermission.'*' -Expected 'ask' -Message "$AgentName asks before source edit/apply_patch tools"
  Assert-Equal -Actual $editPermission.'.opencode/tmp/*' -Expected 'allow' -Message "$AgentName allows file modifications for temporary handoff state"
  Assert-NoWriteToolPattern -EditPermission $editPermission -AgentName $AgentName
  Assert-NoStandaloneWritePermission -Agent $Agent -AgentName $AgentName
}

$rawConfig = Get-Content -Raw -LiteralPath $configPath
$config = Get-JsoncObject -Path $configPath

Assert-FileReferenceExists -RawConfig $rawConfig -RootPath $root
Assert-True -Condition (-not $rawConfig.Contains('"rm -f .opencode/tmp/')) -Message 'config does not auto-allow rm -f for temp files in PowerShell'
Assert-True -Condition (-not $rawConfig.Contains('"test -f .opencode/tmp/')) -Message 'config does not auto-allow test -f for temp files in PowerShell'
Assert-True -Condition (-not $rawConfig.Contains('"write": "allow"')) -Message 'config does not use edit.write tool-name pattern'
Assert-NotContains -Text $rawConfig -Needle 'opencode/nemotron-3-ultra-free' -Message 'config no longer uses Nemotron 3 Ultra Free'
Assert-NotContains -Text $rawConfig -Needle '"deepseek-prompter"' -Message 'config keeps prompter role name model-neutral'
Assert-NotContains -Text $rawConfig -Needle '"deepseek-brainstormer"' -Message 'config keeps brainstormer role name model-neutral'
Assert-NotContains -Text $rawConfig -Needle '"deepseek-implementor"' -Message 'config keeps implementor role name model-neutral'
Assert-NotContains -Text $rawConfig -Needle '"deepseek-sprint-implementor"' -Message 'config keeps sprint implementor role name model-neutral'
Assert-NotContains -Text $rawConfig -Needle 'prompts/deepseek-' -Message 'config keeps prompt file references model-neutral'
Assert-Contains -Text $rawConfig -Needle 'opencode/deepseek-v4-flash-free' -Message 'config uses DeepSeek V4 Flash Free'
Assert-Contains -Text $rawConfig -Needle '".opencode/tmp/*": "allow"' -Message 'config allows handoff writes with path-based edit permission'

$sprintAgent = Get-ObjectPropertyValue -InputObject $config.agent -PropertyName 'sprint-implementor'
Assert-True -Condition ($null -ne $sprintAgent) -Message 'sprint-implementor agent exists'
Assert-Equal -Actual $sprintAgent.mode -Expected 'primary' -Message 'sprint implementor is a primary agent'
Assert-Equal -Actual $sprintAgent.model -Expected 'opencode/deepseek-v4-flash-free' -Message 'sprint implementor uses DeepSeek V4 Flash Free'
Assert-Equal -Actual $sprintAgent.permission.task -Expected 'allow' -Message 'sprint implementor can use subagents'
Assert-Equal -Actual $sprintAgent.permission.question -Expected 'allow' -Message 'sprint implementor can ask approval questions'
Assert-ImplementationEditPermission -Agent $sprintAgent -AgentName 'sprint-implementor'

$sprintCommand = Get-ObjectPropertyValue -InputObject $config.command -PropertyName 'sprint'
Assert-True -Condition ($null -ne $sprintCommand) -Message '/sprint command exists'
Assert-Equal -Actual $sprintCommand.agent -Expected 'sprint-implementor' -Message '/sprint points to sprint implementor'
Assert-Equal -Actual $sprintCommand.template -Expected '{file:command-templates/sprint.md}' -Message '/sprint uses sprint command template'

$workflowAgents = @(
  'prompter',
  'repo-analyzer',
  'brainstormer',
  'implementor',
  'sprint-implementor'
)

foreach ($agentName in $workflowAgents) {
  $workflowAgent = Get-ObjectPropertyValue -InputObject $config.agent -PropertyName $agentName
  Assert-True -Condition ($null -ne $workflowAgent) -Message "$agentName exists"
  Assert-HandoffAllowlist -Agent $workflowAgent -AgentName $agentName
}

foreach ($agentName in @('repo-analyzer', 'brainstormer')) {
  $analysisAgent = Get-ObjectPropertyValue -InputObject $config.agent -PropertyName $agentName
  Assert-ReadOnlyAnalysisTaskAllowlist -Agent $analysisAgent -AgentName $agentName
}

foreach ($agentName in @('prompter', 'repo-analyzer', 'brainstormer')) {
  $handoffAgent = Get-ObjectPropertyValue -InputObject $config.agent -PropertyName $agentName
  Assert-WriteOnlyEditPermission -Agent $handoffAgent -AgentName $agentName
}

foreach ($agentName in @('implementor', 'sprint-implementor')) {
  $implementationAgent = Get-ObjectPropertyValue -InputObject $config.agent -PropertyName $agentName
  Assert-ImplementationEditPermission -Agent $implementationAgent -AgentName $agentName
}

$brainstormPrompt = Get-Content -Raw -LiteralPath (Join-Path $root 'prompts/brainstormer.md')
$brainstormTemplate = Get-Content -Raw -LiteralPath (Join-Path $root 'command-templates/brainstorm.md')
$analyzerPrompt = Get-Content -Raw -LiteralPath (Join-Path $root 'prompts/repo-analyzer.md')
$analyzerTemplate = Get-Content -Raw -LiteralPath (Join-Path $root 'command-templates/analyze.md')
$implementPrompt = Get-Content -Raw -LiteralPath (Join-Path $root 'prompts/implementor.md')
$implementTemplate = Get-Content -Raw -LiteralPath (Join-Path $root 'command-templates/implement.md')
$sprintPrompt = Get-Content -Raw -LiteralPath (Join-Path $root 'prompts/sprint-implementor.md')
$sprintTemplate = Get-Content -Raw -LiteralPath (Join-Path $root 'command-templates/sprint.md')
$gitignore = Get-Content -Raw -LiteralPath (Join-Path $root '.gitignore')

$workflowTexts = @(
  $analyzerPrompt,
  $analyzerTemplate,
  $brainstormPrompt,
  $brainstormTemplate,
  $implementPrompt,
  $implementTemplate,
  $sprintPrompt,
  $sprintTemplate
) -join "`n"

Assert-NotContains -Text $workflowTexts -Needle 'delete it immediately' -Message 'workflow does not delete handoff files immediately after reading'
Assert-NotContains -Text $workflowTexts -Needle 'Delete consumed temporary handoff files immediately' -Message 'workflow does not delete consumed handoffs immediately'
Assert-NotContains -Text $workflowTexts -Needle 'Only after deleting the brainstorm handoff file may you inspect or edit project source files.' -Message 'implementor no longer gates source inspection on early handoff deletion'
Assert-Contains -Text $workflowTexts -Needle 'Final handoff cleanup' -Message 'workflow defines final handoff cleanup'
Assert-Contains -Text $workflowTexts -Needle 'Delete consumed handoff files only during final cleanup' -Message 'workflow deletes consumed handoffs only during final cleanup'

Assert-Contains -Text $analyzerPrompt -Needle 'Command Environment Contract' -Message 'analyzer prompt requires command environment contract'
Assert-Contains -Text $analyzerPrompt -Needle 'delegate by default with the `task` tool' -Message 'analyzer prompt defaults to task-tool delegation'
Assert-Contains -Text $analyzerPrompt -Needle 'launch at least two relevant specialist subagents' -Message 'analyzer prompt requires multiple subagents for cross-area work'
Assert-Contains -Text $analyzerPrompt -Needle 'If the `task` tool is unavailable, blocked, or no specialist applies' -Message 'analyzer prompt reports unavailable delegation'
Assert-Contains -Text $analyzerPrompt -Needle 'WSL Repository Command Prefix' -Message 'analyzer prompt requires WSL repository command prefix'
Assert-Contains -Text $analyzerTemplate -Needle 'WSL Repository Command Prefix' -Message 'analyzer template requires WSL repository command prefix'
Assert-Contains -Text $analyzerTemplate -Needle 'Use specialized subagents by default for repository analysis' -Message 'analyzer template defaults to specialist delegation'
Assert-Contains -Text $analyzerTemplate -Needle 'use the `task` tool to delegate focused read-only exploration' -Message 'analyzer template requires task-tool delegation'
Assert-Contains -Text $analyzerTemplate -Needle 'If the `task` tool is unavailable, blocked, or no specialist applies' -Message 'analyzer template reports unavailable delegation'
Assert-Contains -Text $analyzerPrompt -Needle 'wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy' -Message 'analyzer prompt pins VLAM repo WSL prefix'
Assert-Contains -Text $analyzerPrompt -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'analyzer prompt forbids rm -f in PowerShell'
Assert-Contains -Text $analyzerTemplate -Needle '## 4. Command Environment Contract' -Message 'analyzer report includes command environment contract section'
Assert-Contains -Text $analyzerTemplate -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'analyzer template forbids rm -f in PowerShell'
Assert-Contains -Text $analyzerTemplate -Needle 'before declaring a command or tool unavailable' -Message 'analyzer defines command failure triage'
Assert-Contains -Text $analyzerTemplate -Needle 'PowerShell syntax in WSL/Linux bash' -Message 'analyzer prevents terminal syntax mismatch'
Assert-Contains -Text $analyzerTemplate -Needle 'wsl.exe' -Message 'analyzer records WSL invocation guidance'
Assert-Contains -Text $analyzerPrompt -Needle 'Git Command Safety' -Message 'analyzer prompt requires git command safety guidance'
Assert-Contains -Text $analyzerTemplate -Needle 'Git Command Safety' -Message 'analyzer template requires git command safety guidance'
Assert-Contains -Text $analyzerTemplate -Needle 'Do not combine `git add` and `git commit` with `&&`' -Message 'analyzer template forbids combined git add and commit'
Assert-Contains -Text $analyzerPrompt -Needle 'Run a non-interactive remote/auth preflight before `git push`.' -Message 'analyzer prompt requires push auth preflight'
Assert-Contains -Text $analyzerTemplate -Needle 'Run a non-interactive remote/auth preflight before `git push`.' -Message 'analyzer template requires push auth preflight'
Assert-Contains -Text $analyzerPrompt -Needle 'Dependency And Verification Preflight' -Message 'analyzer prompt requires dependency preflight'
Assert-Contains -Text $analyzerPrompt -Needle 'Dependency setup commands' -Message 'analyzer prompt captures dependency setup commands'
Assert-Contains -Text $analyzerPrompt -Needle 'Canonical VLAM frontend verification commands' -Message 'analyzer prompt pins VLAM frontend verification commands'
Assert-Contains -Text $analyzerTemplate -Needle 'Canonical VLAM frontend verification commands' -Message 'analyzer template pins VLAM frontend verification commands'
Assert-Contains -Text $analyzerPrompt -Needle 'native optional dependency' -Message 'analyzer prompt handles native optional dependencies'
Assert-Contains -Text $analyzerPrompt -Needle 'lightningcss' -Message 'analyzer prompt names lightningcss native dependency risk'
Assert-Contains -Text $analyzerPrompt -Needle 'node_modules/.bin/eslint' -Message 'analyzer prompt captures Node bin shim executable-bit risk'
Assert-Contains -Text $analyzerPrompt -Needle 'chmod +x' -Message 'analyzer prompt includes POSIX executable-bit repair guidance'
Assert-Contains -Text $analyzerTemplate -Needle '## 7. Dependency And Verification Preflight' -Message 'analyzer report includes dependency preflight section'
Assert-Contains -Text $analyzerTemplate -Needle 'Dependency setup commands' -Message 'analyzer template captures dependency setup commands'
Assert-Contains -Text $analyzerTemplate -Needle 'native optional dependency' -Message 'analyzer template handles native optional dependencies'
Assert-Contains -Text $analyzerTemplate -Needle 'lightningcss' -Message 'analyzer template names lightningcss native dependency risk'
Assert-Contains -Text $analyzerTemplate -Needle 'node_modules/.bin/eslint' -Message 'analyzer template captures Node bin shim executable-bit risk'
Assert-Contains -Text $analyzerTemplate -Needle 'chmod +x' -Message 'analyzer template includes POSIX executable-bit repair guidance'

Assert-Contains -Text $brainstormPrompt -Needle 'Sprint Backlog For /sprint' -Message 'brainstorm prompt requires sprint backlog'
Assert-Contains -Text $brainstormPrompt -Needle 'use the `task` tool to ask the relevant read-only specialist subagents' -Message 'brainstorm prompt can delegate thin-context follow-up'
Assert-Contains -Text $brainstormPrompt -Needle 'If you skip specialist follow-up, state why' -Message 'brainstorm prompt explains skipped follow-up delegation'
Assert-Contains -Text $brainstormPrompt -Needle 'If the `task` tool is unavailable or blocked' -Message 'brainstorm prompt reports blocked delegation'
Assert-Contains -Text $brainstormPrompt -Needle 'Every approved brainstorm handoff must use a multi-sprint backlog with at least two sprints.' -Message 'brainstorm prompt always requires multiple sprints'
Assert-Contains -Text $brainstormPrompt -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'brainstorm prompt forbids rm -f in PowerShell'
Assert-Contains -Text $brainstormPrompt -Needle 'Command Environment Contract' -Message 'brainstorm prompt carries command environment contract'
Assert-Contains -Text $brainstormPrompt -Needle 'WSL Repository Command Prefix' -Message 'brainstorm prompt carries WSL repository command prefix'
Assert-Contains -Text $brainstormPrompt -Needle 'Dependency And Verification Preflight' -Message 'brainstorm prompt carries dependency preflight'
Assert-Contains -Text $brainstormPrompt -Needle 'Canonical VLAM frontend verification commands' -Message 'brainstorm prompt carries VLAM verification commands'
Assert-Contains -Text $brainstormPrompt -Needle 'native optional dependency' -Message 'brainstorm prompt carries native dependency guidance'
Assert-Contains -Text $brainstormPrompt -Needle 'node_modules/.bin/eslint' -Message 'brainstorm prompt carries Node bin shim guidance'
Assert-Contains -Text $brainstormPrompt -Needle 'Git Command Safety' -Message 'brainstorm prompt carries git command safety'
Assert-Contains -Text $brainstormPrompt -Needle 'non-interactive remote/auth preflight' -Message 'brainstorm prompt carries push auth preflight'
Assert-Contains -Text $brainstormTemplate -Needle '## Sprint Backlog For /sprint' -Message 'brainstorm handoff includes sprint backlog section'
Assert-Contains -Text $brainstormTemplate -Needle 'use the `task` tool to ask relevant read-only specialist subagents' -Message 'brainstorm template can delegate thin-context follow-up'
Assert-Contains -Text $brainstormTemplate -Needle 'If specialist follow-up is skipped, explain why' -Message 'brainstorm template explains skipped follow-up delegation'
Assert-Contains -Text $brainstormTemplate -Needle 'If the `task` tool is unavailable or blocked' -Message 'brainstorm template reports blocked delegation'
Assert-Contains -Text $brainstormTemplate -Needle 'Every approved brainstorm handoff must include a multi-sprint backlog with at least two sprints.' -Message 'brainstorm template always requires multiple sprints'
Assert-Contains -Text $brainstormTemplate -Needle 'Backlog type: multi-sprint' -Message 'brainstorm handoff marks backlog as multi-sprint'
Assert-Contains -Text $brainstormTemplate -Needle 'Minimum sprint count: at least 2' -Message 'brainstorm handoff records minimum sprint count'
Assert-NotContains -Text $brainstormTemplate -Needle 'For small work, define a one-sprint backlog' -Message 'brainstorm template no longer permits one-sprint backlog'
Assert-NotContains -Text $brainstormTemplate -Needle 'single-sprint or multi-sprint' -Message 'brainstorm template no longer offers single-sprint backlog type'
Assert-NotContains -Text $brainstormTemplate -Needle 'or omit if single-sprint' -Message 'brainstorm template always expects Sprint 2'
Assert-Contains -Text $brainstormTemplate -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'brainstorm template forbids rm -f in PowerShell'
Assert-Contains -Text $brainstormTemplate -Needle '## Command Environment Contract' -Message 'brainstorm handoff includes command environment contract'
Assert-Contains -Text $brainstormTemplate -Needle '## WSL Repository Command Prefix' -Message 'brainstorm handoff includes WSL repository command prefix'
Assert-Contains -Text $brainstormTemplate -Needle '## Dependency And Verification Preflight' -Message 'brainstorm handoff includes dependency preflight'
Assert-Contains -Text $brainstormTemplate -Needle 'Canonical VLAM frontend verification commands' -Message 'brainstorm handoff includes VLAM verification commands'
Assert-Contains -Text $brainstormTemplate -Needle '## Git Command Safety' -Message 'brainstorm handoff includes git command safety'
Assert-Contains -Text $brainstormTemplate -Needle 'non-interactive remote/auth preflight' -Message 'brainstorm handoff includes push auth preflight'
Assert-Contains -Text $brainstormTemplate -Needle 'Dependency preflight:' -Message 'brainstorm sprint entries include dependency preflight'
Assert-Contains -Text $brainstormTemplate -Needle 'node_modules/.bin/eslint' -Message 'brainstorm handoff includes Node bin shim guidance'
Assert-Contains -Text $brainstormTemplate -Needle 'Commit-message guidance' -Message 'brainstorm sprint entries include commit message guidance'

Assert-Contains -Text $implementPrompt -Needle 'If the brainstorm handoff marks the task as multi-sprint' -Message 'implement prompt guards multi-sprint work'
Assert-Contains -Text $implementPrompt -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'implement prompt forbids rm -f in PowerShell'
Assert-Contains -Text $implementPrompt -Needle 'Do not run a repository command until you have matched the command syntax to the intended terminal' -Message 'implement prompt enforces command syntax matching'
Assert-Contains -Text $implementPrompt -Needle 'Use `write` only for `.opencode/tmp` handoff or sprint-state files.' -Message 'implement prompt restricts write to temporary handoff state'
Assert-Contains -Text $implementPrompt -Needle 'Do not use `write` for source, test, config, or documentation implementation edits' -Message 'implement prompt keeps source edits on edit/apply_patch'
Assert-Contains -Text $implementTemplate -Needle 'If the brainstorm handoff marks the task as multi-sprint' -Message 'implement template guards multi-sprint work'
Assert-Contains -Text $implementTemplate -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'implement template forbids rm -f in PowerShell'
Assert-Contains -Text $implementTemplate -Needle '/sprint' -Message 'implement guard points to /sprint'
Assert-Contains -Text $implementTemplate -Needle 'If a command fails with command not found, syntax errors, path errors, or tool-not-recognized errors' -Message 'implement template triages terminal mismatch before claiming unavailable'
Assert-Contains -Text $implementTemplate -Needle 'Run the equivalent command in the intended runtime before declaring failure' -Message 'implement template requires intended-runtime retry'
Assert-Contains -Text $implementTemplate -Needle 'Use `write` only for `.opencode/tmp` handoff or sprint-state files.' -Message 'implement template restricts write to temporary handoff state'
Assert-Contains -Text $implementTemplate -Needle 'Do not use `write` for source, test, config, or documentation implementation edits' -Message 'implement template keeps source edits on edit/apply_patch'

Assert-Contains -Text $sprintPrompt -Needle 'never implement the full backlog in one run' -Message 'sprint prompt refuses full backlog implementation'
Assert-Contains -Text $sprintPrompt -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'sprint prompt forbids rm -f in PowerShell'
Assert-Contains -Text $sprintPrompt -Needle 'Do not run a repository command until you have matched the command syntax to the intended terminal' -Message 'sprint prompt enforces command syntax matching'
Assert-Contains -Text $sprintPrompt -Needle 'Use `write` only for `.opencode/tmp` handoff or sprint-state files.' -Message 'sprint prompt restricts write to temporary handoff state'
Assert-Contains -Text $sprintPrompt -Needle 'Do not use `write` for source, test, config, or documentation implementation edits' -Message 'sprint prompt keeps source edits on edit/apply_patch'
Assert-Contains -Text $sprintTemplate -Needle 'If neither `.opencode/tmp/sprint-backlog.md` nor `.opencode/tmp/brainstorm-handoff.md` exists, stop and tell the user to run `/brainstorm` first.' -Message 'sprint stops when no backlog source exists'
Assert-Contains -Text $sprintTemplate -Needle 'Never use `rm -f` in Windows PowerShell' -Message 'sprint template forbids rm -f in PowerShell'
Assert-Contains -Text $sprintTemplate -Needle 'Select only the first pending or in-progress sprint' -Message 'sprint selects only next sprint'
Assert-Contains -Text $sprintTemplate -Needle 'If the user asks you to do all remaining sprints' -Message 'sprint refuses do-all request'
Assert-Contains -Text $sprintTemplate -Needle 'If a command fails with command not found, syntax errors, path errors, or tool-not-recognized errors' -Message 'sprint template triages terminal mismatch before claiming unavailable'
Assert-Contains -Text $sprintTemplate -Needle 'Run the equivalent command in the intended runtime before declaring failure' -Message 'sprint template requires intended-runtime retry'
Assert-Contains -Text $sprintTemplate -Needle 'Use `write` only for `.opencode/tmp` handoff or sprint-state files.' -Message 'sprint template restricts write to temporary handoff state'
Assert-Contains -Text $sprintTemplate -Needle 'Do not use `write` for source, test, config, or documentation implementation edits' -Message 'sprint template keeps source edits on edit/apply_patch'
Assert-Contains -Text $sprintTemplate -Needle 'After completing the sprint, rewrite `.opencode/tmp/sprint-backlog.md`' -Message 'sprint rewrites backlog after sprint'
Assert-Contains -Text $sprintTemplate -Needle 'If all sprints are complete, delete `.opencode/tmp/sprint-backlog.md`' -Message 'sprint deletes backlog after final sprint'
Assert-Contains -Text $sprintTemplate -Needle 'Use the `write` tool to create or overwrite `.opencode/tmp/sprint-backlog.md`' -Message 'sprint state uses write tool'
Assert-Contains -Text $sprintTemplate -Needle 'Use the question tool to ask for approval before starting the selected sprint' -Message 'sprint asks before starting'
Assert-Contains -Text $sprintTemplate -Needle 'Use the question tool to ask the user for approval before creating the sprint commit' -Message 'sprint asks before commit'
Assert-Contains -Text $sprintTemplate -Needle 'After committing, use the question tool to ask the user for approval before pushing' -Message 'sprint asks before push'

foreach ($implementationWorkflow in @(
  @{ Name = 'implement prompt'; Text = $implementPrompt },
  @{ Name = 'implement template'; Text = $implementTemplate },
  @{ Name = 'sprint prompt'; Text = $sprintPrompt },
  @{ Name = 'sprint template'; Text = $sprintTemplate }
)) {
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Run dependency setup in the intended runtime before lint, test, typecheck, or build commands.' -Message "$($implementationWorkflow.Name) runs dependency setup before verification"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'If a Node.js verification command fails because a native optional dependency is missing' -Message "$($implementationWorkflow.Name) detects native optional dependency failures"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Do not treat missing native optional packages as application code failures until dependency setup has been repaired in the intended runtime.' -Message "$($implementationWorkflow.Name) classifies native dependency failures as setup issues first"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'lightningcss' -Message "$($implementationWorkflow.Name) names lightningcss as a native dependency example"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Before running Node package executables in POSIX runtimes, verify local package binary shims are executable.' -Message "$($implementationWorkflow.Name) verifies Node bin shim executable bits"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'node_modules/.bin/eslint' -Message "$($implementationWorkflow.Name) names eslint bin shim example"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'chmod +x' -Message "$($implementationWorkflow.Name) includes executable-bit repair command"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Run `git add` and `git commit` as separate commands.' -Message "$($implementationWorkflow.Name) separates git add and commit"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Do not combine `git add` and `git commit` with `&&`' -Message "$($implementationWorkflow.Name) forbids combined git add and commit"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Do not combine git completion steps with `&&`.' -Message "$($implementationWorkflow.Name) forbids chained git completion commands"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Do not wrap `git commit -m` inside a nested `bash -lc` string when invoking WSL from Windows.' -Message "$($implementationWorkflow.Name) forbids nested bash commit quoting"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'For git status, git diff, git add, git commit, and git push in WSL from Windows, do not use `bash -lc`; invoke `git` directly through `wsl.exe`.' -Message "$($implementationWorkflow.Name) forbids bash-lc for WSL git completion"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Run `git status`, `git diff`, `git add`, `git diff --cached --stat`, `git commit`, and `git push` as separate commands.' -Message "$($implementationWorkflow.Name) requires one git action per command"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'If a previous sprint backlog or brainstorm handoff lacks `Git Command Safety`, follow this prompt/template over the stale handoff.' -Message "$($implementationWorkflow.Name) overrides stale handoffs for git safety"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Forbidden example: `wsl.exe -d <distro> --cd <repo-root> bash -lc' -Message "$($implementationWorkflow.Name) includes forbidden bash-lc git example"
  Assert-Contains -Text $implementationWorkflow.Text -Needle "wsl.exe -d <distro> --cd <repo-root> git commit -m '<message>'" -Message "$($implementationWorkflow.Name) documents direct WSL git commit invocation"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Before pushing, run `git remote -v`, `git status -sb`, and `git branch --show-current` as separate commands.' -Message "$($implementationWorkflow.Name) inspects remote and branch before push"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Run a non-interactive remote/auth preflight before `git push`.' -Message "$($implementationWorkflow.Name) runs push auth preflight"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git ls-remote --exit-code origin HEAD' -Message "$($implementationWorkflow.Name) uses non-interactive ls-remote preflight"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'ssh -T -o BatchMode=yes -o ConnectTimeout=10' -Message "$($implementationWorkflow.Name) uses non-interactive SSH auth preflight"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'env GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=Never git push --porcelain <remote> <branch>' -Message "$($implementationWorkflow.Name) uses non-interactive porcelain push"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Set a bounded timeout for push commands when the tool supports timeouts, and treat timeout as auth/network blocked instead of retrying blindly.' -Message "$($implementationWorkflow.Name) treats push timeout as auth/network blocker"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Canonical VLAM frontend verification commands' -Message "$($implementationWorkflow.Name) pins VLAM frontend verification commands"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Every repository command for the VLAM-Academy repo must start with `wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy`.' -Message "$($implementationWorkflow.Name) requires VLAM repo WSL prefix"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run build 2>&1"' -Message "$($implementationWorkflow.Name) includes exact repo-root VLAM build command"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'wsl.exe -d Ubuntu --cd /home/sk/projects/VLAM-Academy bash -lc "cd frontend && source ~/.nvm/nvm.sh && nvm use 24.15.0 && npm run lint 2>&1"' -Message "$($implementationWorkflow.Name) includes exact repo-root VLAM lint command"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'Do not substitute `npx eslint`, a different working directory, a different Node version, or a command that omits `source ~/.nvm/nvm.sh`.' -Message "$($implementationWorkflow.Name) forbids substituting VLAM verification commands"
  Assert-Contains -Text $implementationWorkflow.Text -Needle 'If a previous sprint backlog or brainstorm handoff lacks these canonical VLAM commands, follow this prompt/template over the stale handoff.' -Message "$($implementationWorkflow.Name) overrides stale handoffs for VLAM verification"
}

Assert-Contains -Text $gitignore -Needle '.opencode/tmp/' -Message '.opencode/tmp remains ignored'

Write-Output 'Sprint workflow validation passed.'
