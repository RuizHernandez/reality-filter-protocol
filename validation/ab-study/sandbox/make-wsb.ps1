# Generates ab-study.wsb (Windows Sandbox config) for THIS machine.
# The .wsb embeds host paths, so it is generated, not committed.
#
# Usage (host PowerShell):  .\make-wsb.ps1 -SecretsDir C:\ab-secrets
#
# Maps into the sandbox:
#   - this repository READ-ONLY: agents run with permissions bypassed and
#     must not be able to alter the host repository or its .git
#   - validation/ab-study/runs read-write at C:\ab-runs, the only writable path
#   - host Node.js, Git for Windows, and the global npm folder (read-only)
#   - a secrets folder holding secrets.env (read-only). You create it; the
#     scripts only source it, never print it.
param(
  [Parameter(Mandatory = $true)][string]$SecretsDir
)
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$node = Split-Path (Get-Command node).Source
$git = Split-Path (Split-Path (Get-Command git).Source)
$npmGlobal = Join-Path $env:APPDATA 'npm'
if (-not (Test-Path (Join-Path $SecretsDir 'secrets.env'))) {
  throw "No secrets.env in $SecretsDir -- create it first (see sandbox/README.md)."
}

$sb = 'C:\Users\WDAGUtilityAccount'
function Map($host_, $sandbox, $ro) {
  "    <MappedFolder><HostFolder>$host_</HostFolder><SandboxFolder>$sandbox</SandboxFolder><ReadOnly>$ro</ReadOnly></MappedFolder>"
}

$xml = @"
<Configuration>
  <Networking>Enable</Networking>
  <vGPU>Disable</vGPU>
  <ClipboardRedirection>Disable</ClipboardRedirection>
  <MemoryInMB>8192</MemoryInMB>
  <MappedFolders>
$(Map $repo "$sb\rfp" 'true')
$(Map (Join-Path $repo 'validation\ab-study\runs') 'C:\ab-runs' 'false')
$(Map $node 'C:\tools\nodejs' 'true')
$(Map $git 'C:\tools\git' 'true')
$(Map $npmGlobal 'C:\tools\npm' 'true')
$(Map $SecretsDir 'C:\secrets' 'true')
  </MappedFolders>
  <LogonCommand>
    <Command>powershell -ExecutionPolicy Bypass -NoExit -File $sb\rfp\validation\ab-study\sandbox\bootstrap.ps1</Command>
  </LogonCommand>
</Configuration>
"@

$out = Join-Path $PSScriptRoot 'ab-study.wsb'
Set-Content -Path $out -Value $xml -Encoding UTF8
"written: $out -- double-click it to start the sandbox"
