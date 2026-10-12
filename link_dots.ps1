#requires -Version 5.1
<#
.SYNOPSIS
Links files and directories described by first-level dot.yaml files.
.DESCRIPTION
Place this script at ~/.dotfiles/link_dots.ps1 and run it from PowerShell on Windows.
Each first-level directory (except .git and names listed in ignore_dots.yaml or
ignore.yml at the dotfiles root) may contain a dot.yaml with a top-level links:
mapping. Keys are files or directories directly in that directory. Values are
destination paths. Existing destinations are removed before links are made.

The parser supports plain, single-quoted, and double-quoted scalar paths in the
links: mapping. Quote paths containing # or trailing spaces. It does not support
YAML sequences, aliases, block scalars, or nested mappings under links:.

Destination paths may start with ~, contain %ENVIRONMENT_VARIABLES%, or be
absolute. Other relative destinations are resolved from the user's home folder.
Use -WhatIf to preview changes.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-PathScalar {
    param([string] $Text, [string] $Location)

    $value = $Text.Trim()
    if ($value.StartsWith("'")) {
        if ($value -notmatch "^'(?:[^']|'')*'(?:\s+#.*)?$") {
            throw "Invalid single-quoted path at $Location"
        }
        $match = [regex]::Match($value, "^'((?:[^']|'')*)'")
        return $match.Groups[1].Value.Replace("''", "'")
    }
    if ($value.StartsWith('"')) {
        if ($value -notmatch '^"(?:[^"\\]|\\.)*"(?:\s+#.*)?$') {
            throw "Invalid double-quoted path at $Location"
        }
        $match = [regex]::Match($value, '^"(?:[^"\\]|\\.)*"')
        try { return ($match.Value | ConvertFrom-Json) }
        catch { throw "Invalid double-quoted path at ${Location}: $_" }
    }
    $value = ($value -replace '\s+#.*$', '').Trim()
    if (-not $value -or $value -match '^[\[\]{},&*!|>]') {
        throw "Unsupported or empty path at $Location"
    }
    return $value
}

function Get-LinkEntries {
    param([string] $YamlPath)

    $lines = [IO.File]::ReadAllLines($YamlPath)
    $inLinks = $false
    $foundLinks = $false
    $entryIndent = -1
    $entries = New-Object 'System.Collections.Generic.List[object]'
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $location = '{0}:{1}' -f $YamlPath, ($i + 1)
        if ($line -match '^\s*(?:#.*)?$') { continue }
        if ($line -match '^\s*\t') { throw "Tabs are not supported for indentation at $location" }
        $indent = ([regex]::Match($line, '^ *')).Length

        if (-not $inLinks) {
            if ($indent -eq 0 -and $line -match '^links:\s*(?:#.*)?$') {
                if ($foundLinks) { throw "Duplicate links: key at $location" }
                $foundLinks = $true
                $inLinks = $true
            } elseif ($indent -eq 0 -and $line -match '^links\s*:') {
                throw "links: must be a block mapping at $location"
            }
            continue
        }
        if ($indent -eq 0) { $inLinks = $false; continue }
        if ($entryIndent -lt 0) { $entryIndent = $indent }
        if ($indent -ne $entryIndent) { throw "Nested or inconsistent links: entry at $location" }

        $body = $line.Substring($indent)
        $quote = [char]0
        $separator = -1
        for ($j = 0; $j -lt $body.Length; $j++) {
            $ch = $body[$j]
            if ($quote -eq [char]0) {
                if ($ch -eq "'" -or $ch -eq '"') { $quote = $ch }
                elseif ($ch -eq ':' -and ($j + 1 -eq $body.Length -or [char]::IsWhiteSpace($body[$j + 1]))) {
                    $separator = $j; break
                }
            } elseif ($quote -eq '"' -and $ch -eq '\') {
                $j++
            } elseif ($ch -eq $quote) {
                if ($quote -eq "'" -and $j + 1 -lt $body.Length -and $body[$j + 1] -eq "'") { $j++ }
                else { $quote = [char]0 }
            }
        }
        if ($separator -lt 0) { throw "Expected 'source: destination' at $location" }
        $source = Read-PathScalar $body.Substring(0, $separator) $location
        $destination = Read-PathScalar $body.Substring($separator + 1) $location
        $entries.Add([pscustomobject]@{ Source = $source; Destination = $destination; Location = $location })
    }
    return $entries.ToArray()
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
                        $value = Read-PathScalar $inline $location
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
            $value = Read-PathScalar $Matches[1] $location
            if ($value -eq '.' -or $value -eq '..' -or $value -match '[\\/:*?"<>|]') {
                throw "Ignore value must be a first-level directory name at $location"
            }
            $ignored[$value] = $true
        }
    }
    return $ignored
}

function Test-WithinPath {
    param([string] $Path, [string] $Parent)
    $parentWithSlash = $Parent.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    return $Path.Equals($Parent, [StringComparison]::OrdinalIgnoreCase) -or
        $Path.StartsWith($parentWithSlash, [StringComparison]::OrdinalIgnoreCase)
}

function Resolve-Destination {
    param([string] $Value, [string] $HomePath)
    $expanded = [Environment]::ExpandEnvironmentVariables($Value)
    if ($expanded -eq '~') { $expanded = $HomePath }
    elseif ($expanded.StartsWith('~\') -or $expanded.StartsWith('~/')) {
        $expanded = Join-Path $HomePath $expanded.Substring(2)
    }
    if (-not [IO.Path]::IsPathRooted($expanded)) { $expanded = Join-Path $HomePath $expanded }
    return [IO.Path]::GetFullPath($expanded)
}

function Remove-Destination {
    param([string] $Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return }
    if ($item.PSIsContainer -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        # Delete only the junction/symlink itself, never its target.
        [IO.Directory]::Delete($Path, $false)
    } elseif ($item.PSIsContainer) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    } else {
        Remove-Item -LiteralPath $Path -Force
    }
}

$homePath = [IO.Path]::GetFullPath($HOME)
$dotfilesPath = [IO.Path]::GetFullPath($PSScriptRoot)
$ignored = Read-IgnoreNames $dotfilesPath
$plans = New-Object 'System.Collections.Generic.List[object]'

foreach ($folder in (Get-ChildItem -LiteralPath $dotfilesPath -Directory -Force |
    Where-Object { $_.Name -ne '.git' -and -not $ignored.ContainsKey($_.Name) })) {
    $yamlPath = Join-Path $folder.FullName 'dot.yaml'
    if (-not (Test-Path -LiteralPath $yamlPath -PathType Leaf)) { continue }
    foreach ($entry in (Get-LinkEntries $yamlPath)) {
        if ($entry.Source -eq '.' -or $entry.Source -eq '..' -or
            $entry.Source -match '[\\/]' -or [IO.Path]::IsPathRooted($entry.Source)) {
            throw "Source must name a direct child of $($folder.FullName) at $($entry.Location)"
        }
        $sourcePath = [IO.Path]::GetFullPath((Join-Path $folder.FullName $entry.Source))
        $sourceItem = Get-Item -LiteralPath $sourcePath -Force -ErrorAction SilentlyContinue
        if ($null -eq $sourceItem) { throw "Source does not exist: $sourcePath ($($entry.Location))" }
        $destinationPath = Resolve-Destination $entry.Destination $homePath
        if (-not $sourceItem.PSIsContainer -and
            -not [IO.Path]::GetPathRoot($sourcePath).Equals(
                [IO.Path]::GetPathRoot($destinationPath), [StringComparison]::OrdinalIgnoreCase)) {
            throw "A file hardlink must be on the same drive: $sourcePath -> $destinationPath ($($entry.Location))"
        }
        if ((Test-WithinPath $destinationPath $dotfilesPath) -or
            (Test-WithinPath $dotfilesPath $destinationPath)) {
            throw "Destination would overwrite or enter the dotfiles directory: $destinationPath ($($entry.Location))"
        }
        $plans.Add([pscustomobject]@{
            Source = $sourcePath
            Destination = $destinationPath
            IsDirectory = [bool] $sourceItem.PSIsContainer
            Location = $entry.Location
        })
    }
}

# Validate every mapping before changing any destination.
for ($i = 0; $i -lt $plans.Count; $i++) {
    for ($j = $i + 1; $j -lt $plans.Count; $j++) {
        if ((Test-WithinPath $plans[$i].Destination $plans[$j].Destination) -or
            (Test-WithinPath $plans[$j].Destination $plans[$i].Destination)) {
            throw "Overlapping destinations: $($plans[$i].Destination) and $($plans[$j].Destination)"
        }
    }
}

foreach ($plan in $plans) {
    $kind = if ($plan.IsDirectory) { 'junction' } else { 'hardlink' }
    if (-not $PSCmdlet.ShouldProcess($plan.Destination, "Replace destination with $kind to $($plan.Source)")) { continue }
    try {
        Remove-Destination $plan.Destination
        $parent = Split-Path -Parent $plan.Destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $itemType = if ($plan.IsDirectory) { 'Junction' } else { 'HardLink' }
        New-Item -ItemType $itemType -Path $plan.Destination -Target $plan.Source | Out-Null
        Write-Host "$kind`: $($plan.Destination) -> $($plan.Source)"
    } catch {
        Write-Error "Failed to link $($plan.Location): $_"
    }
}

