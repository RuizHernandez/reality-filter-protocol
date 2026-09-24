# Runs at sandbox logon. Puts the read-only host tools on PATH and opens a
# Git Bash shell in the study directory. Starts nothing that costs money:
# batches are launched by hand with sandbox/run-batch.sh.
$ErrorActionPreference = 'Stop'
$env:Path = "C:\tools\nodejs;C:\tools\npm;C:\tools\git\cmd;C:\tools\git\bin;C:\tools\git\usr\bin;$env:Path"
[Environment]::SetEnvironmentVariable('Path', $env:Path, 'User')
[Environment]::SetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', 'C:\tools\git\bin\bash.exe', 'User')
# The npm install is read-only; an updater that tries to write there fails noisily.
[Environment]::SetEnvironmentVariable('DISABLE_AUTOUPDATER', '1', 'User')
[Environment]::SetEnvironmentVariable('AB_RUNS_DIR', '/c/ab-runs', 'User')
$env:CLAUDE_CODE_GIT_BASH_PATH = 'C:\tools\git\bin\bash.exe'
$env:DISABLE_AUTOUPDATER = '1'
$env:AB_RUNS_DIR = '/c/ab-runs'

$study = "$env:USERPROFILE\rfp\validation\ab-study"
Write-Host "A/B sandbox ready. Study dir: $study"
Write-Host "Next: bash sandbox/run-batch.sh <backend> <n> (see sandbox/README.md)"
Start-Process 'C:\tools\git\bin\bash.exe' -ArgumentList '--login', '-i' -WorkingDirectory $study
