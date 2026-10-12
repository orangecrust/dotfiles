#requires -Version 5.1
<#
.SYNOPSIS
Runs install commands from first-level dot.yaml files in dependency order.
.DESCRIPTION
Place this script at ~/.dotfiles/install_dots.ps1. It reads every first-level
directory except .git and names listed in ignore_dots.yaml or ignore.yml at the
dotfiles root, then runs each installs command from that directory.
Dependencies in depends are resolved relative to the directory containing dot.yaml.
Ignored dependencies are treated as already installed.

Supported forms for installs and depends are one value on the same line, or
indented values on following lines, optionally prefixed by "- ". installs also
accepts "|" followed by indented command lines. Other top-level keys are ignored.
This intentionally supports only these simple YAML forms; complex YAML requires
a full YAML parser. Use -WhatIf to view the planned execution order.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Scalar {
    param([string] $Text, [string] $Location, [string] $Kind)
    $value = $Text.Trim()
    if (-not $value) { throw "Empty value at $Location" }
    if ($value.StartsWith("'")) {
        if ($value -notmatch "^'(?:[^']|'')*'(?:\s+#.*)?$") {
            throw "Invalid single-quoted value at $Location"
        }
        return [regex]::Match($value, "^'((?:[^']|'')*)'").Groups[1].Value.Replace("''", "'")
    }
    if ($value.StartsWith('"')) {
        if ($value -notmatch '^"(?:[^"\\]|\\.)*"(?:\s+#.*)?$') {
            throw "Invalid double-quoted value at $Location"
        }
        $quoted = [regex]::Match($value, '^"(?:[^"\\]|\\.)*"').Value
        try { return ($quoted | ConvertFrom-Json) }
        catch { throw "Invalid double-quoted value at ${Location}: $_" }
    }
    if ($Kind -eq 'depends') {
        $value = ($value -replace '\s+#.*$', '').Trim()
        if (-not $value -or $value -match '^[\[\]{},&*!>|]') {
            throw "Unsupported dependency value at $Location"
        }
    }
    return $value
}

function Read-DotYaml {
    param([string] $Path)
    $result = [pscustomobject]@{
        Installs = (New-Object 'System.Collections.Generic.List[string]')
        Depends = (New-Object 'System.Collections.Generic.List[string]')
    }
    $active = $null
    $itemIndent = -1
    $seen = @{}
    $lines = [IO.File]::ReadAllLines($Path)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $location = '{0}:{1}' -f $Path, ($i + 1)
        if ($line -match '^\s*(?:#.*)?$') { continue }
        if ($line -match '^( +)?\t') { throw "Tab indentation is unsupported at $location" }
        $indent = [regex]::Match($line, '^ *').Length
        if ($indent -eq 0) {
            $active = $null
            $itemIndent = -1
            if ($line -match '^(installs|depends)\s*:\s*(.*?)\s*$') {
                $active = $Matches[1]
                $inline = $Matches[2]
                if ($seen.ContainsKey($active)) { throw "Duplicate ${active}: key at $location" }
                $seen[$active] = $true
                if ($inline -and $inline -notmatch '^#') {
                    if ($inline -eq '|') {
                        if ($active -ne 'installs') { throw "Block scalar unsupported for depends at $location" }
                    } else {
                        $result.$active.Add((Read-Scalar $inline $location $active))
                        $active = $null
                    }
                }
            }
            continue
        }
        if (-not $active) { continue }
        if ($itemIndent -lt 0) { $itemIndent = $indent }
        if ($indent -ne $itemIndent) { throw "Inconsistent indentation under ${active}: at $location" }
        $item = $line.Substring($indent)
        if ($item -match '^-\s+(.*)$') { $item = $Matches[1] }
        $result.$active.Add((Read-Scalar $item $location $active))
    }
    return $result
}

function Read-IgnoreNames {
    param([string] $Root)
    $ignored = @{}
    foreach ($fileName in @('ignore_dots.yaml', 'ignore.yml')) {
        $path = Join-Path $Root $fileName
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $inIgnore = $false
        $itemIndent = -1
        $seen = $false
        $lines = [IO.File]::ReadAllLines($path)
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            $location = '{0}:{1}' -f $path, ($i + 1)
            if ($line -match '^\s*(?:#.*)?$') { continue }
            if ($line -match '^( +)?\t') { throw "Tab indentation is unsupported at $location" }
            $indent = [regex]::Match($line, '^ *').Length
            if ($indent -eq 0) {
                $inIgnore = $false
                $itemIndent = -1
                if ($line -match '^ignore\s*:\s*(.*?)\s*$') {
                    if ($seen) { throw "Duplicate ignore: key at $location" }
                    $seen = $true
                    $inIgnore = $true
                    $inline = $Matches[1]
                    if ($inline -and $inline -notmatch '^#') {
                        if ($inline -eq '[]') { $inIgnore = $false; continue }
                        $value = Read-Scalar $inline $location 'depends'
                        if ($value -eq '.' -or $value -eq '..' -or $value -match '[\\/:*?"<>|]') {
                            throw "Ignore value must be a first-level directory name at $location"
                        }
                        $ignored[$value] = $true
                        $inIgnore = $false
                    }
                }
                continue
            }
            if (-not $inIgnore) { continue }
            if ($itemIndent -lt 0) { $itemIndent = $indent }
            if ($indent -ne $itemIndent -or $line.Substring($indent) -notmatch '^-\s+(.+)$') {
                throw "Expected an ignore list item at $location"
            }
            $value = Read-Scalar $Matches[1] $location 'depends'
            if ($value -eq '.' -or $value -eq '..' -or $value -match '[\\/:*?"<>|]') {
                throw "Ignore value must be a first-level directory name at $location"
            }
            $ignored[$value] = $true
        }
    }
    return $ignored
}

$root = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\', '/')
$ignored = Read-IgnoreNames $root
$packages = @{}
foreach ($folder in (Get-ChildItem -LiteralPath $root -Directory -Force |
    Where-Object { $_.Name -ne '.git' -and -not $ignored.ContainsKey($_.Name) } | Sort-Object Name)) {
    $yamlPath = Join-Path $folder.FullName 'dot.yaml'
    if (-not (Test-Path -LiteralPath $yamlPath -PathType Leaf)) { continue }
    $config = Read-DotYaml $yamlPath
    $packages[$folder.Name] = [pscustomobject]@{
        Name = $folder.Name
        Directory = $folder.FullName
        YamlPath = $yamlPath
        Installs = $config.Installs
        Depends = $config.Depends
        Dependencies = (New-Object 'System.Collections.Generic.List[string]')
    }
}

# Resolve every dependency and reject missing packages before running commands.
foreach ($package in $packages.Values) {
    foreach ($dependency in $package.Depends) {
        $dependencyPath = [IO.Path]::GetFullPath((Join-Path $package.Directory $dependency))
        $parent = [IO.Path]::GetDirectoryName($dependencyPath).TrimEnd('\', '/')
        if (-not $parent.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Dependency must point to a first-level dotfiles directory: $dependency ($($package.YamlPath))"
        }
        $name = [IO.Path]::GetFileName($dependencyPath)
        if ($ignored.ContainsKey($name)) { continue }
        if (-not $packages.ContainsKey($name)) {
            throw "Dependency has no dot.yaml: $dependency ($($package.YamlPath))"
        }
        if (-not $package.Dependencies.Contains($name)) { $package.Dependencies.Add($name) }
    }
}

$state = @{}
$order = New-Object 'System.Collections.Generic.List[string]'
function Visit-Package {
    param([string] $Name, [string[]] $Trail)
    if ($state[$Name] -eq 2) { return }
    if ($state[$Name] -eq 1) {
        throw "Dependency cycle: $(($Trail + $Name) -join ' -> ')"
    }
    $state[$Name] = 1
    foreach ($dependency in ($packages[$Name].Dependencies | Sort-Object)) {
        Visit-Package $dependency ($Trail + $Name)
    }
    $state[$Name] = 2
    $order.Add($Name)
}
foreach ($name in ($packages.Keys | Sort-Object)) { Visit-Package $name @() }

foreach ($name in $order) {
    $package = $packages[$name]
    foreach ($command in $package.Installs) {
        if (-not $PSCmdlet.ShouldProcess($package.Directory, "Run: $command")) { continue }
        Write-Host "[$name] $command"
        Push-Location -LiteralPath $package.Directory
        try {
            $global:LASTEXITCODE = 0
            Invoke-Expression $command
            $succeeded = $?
            if (-not $succeeded -or $global:LASTEXITCODE -ne 0) {
                throw "Command failed with exit code $global:LASTEXITCODE"
            }
        } catch {
            throw "Install failed in $($package.YamlPath) while running '$command': $_"
        } finally {
            Pop-Location
        }
    }
}

