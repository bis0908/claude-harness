# claude-harness 전역 설치 (Windows / PowerShell)
# 골격 agents/ 와 skills/ 를 ~/.claude 로 설치한다. examples/ 는 설치하지 않는다.
#
# 사용법:
#   ./install.ps1            복사 설치 (기본)
#   ./install.ps1 -Symlink   심볼릭 링크 설치 (repo 갱신 즉시 반영, 개발자 모드/관리자 권한 필요)

param([switch]$Symlink)

$ErrorActionPreference = "Stop"
$repo   = $PSScriptRoot
$target = Join-Path $env:USERPROFILE ".claude"

New-Item -ItemType Directory -Force -Path (Join-Path $target "agents") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $target "skills") | Out-Null

function Install-Item($src, $dst) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    if ($Symlink) {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
        Write-Host "  link  $dst"
    } else {
        Copy-Item $src $dst -Recurse -Force
        Write-Host "  copy  $dst"
    }
}

Write-Host "claude-harness → $target ($(if ($Symlink) {'symlink'} else {'copy'}))"

Write-Host "[agents]"
Get-ChildItem (Join-Path $repo "agents") -Filter *.md | ForEach-Object {
    Install-Item $_.FullName (Join-Path $target "agents\$($_.Name)")
}

Write-Host "[skills]"
Get-ChildItem (Join-Path $repo "skills") -Directory | ForEach-Object {
    Install-Item $_.FullName (Join-Path $target "skills\$($_.Name)")
}

Write-Host "완료. 새 Claude Code 세션에서 /orchestrate 로 진입하세요."
