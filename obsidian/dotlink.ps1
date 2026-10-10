# Usage: .\dotlink.ps1 [--dir <project-folder-name>]

$root = $PSScriptRoot
$source = Join-Path $root '.obsidian'

if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Source directory not found: $source"
}

$projects = @(Get-ChildItem -LiteralPath $root -Directory -Force |
    Where-Object { $_.FullName -ne $source })

if ($args.Count -eq 2 -and $args[0] -ceq '--dir') {
    $projectName = $args[1]
    $projects = @($projects | Where-Object { $_.Name -eq $projectName })
    if ($projects.Count -eq 0) {
        throw "Project folder not found directly under ${root}: $($args[1])"
    }
}
elseif ($args.Count -ne 0) {
    throw 'Usage: .\dotlink.ps1 [--dir <project-folder-name>]'
}

$failed = $false
foreach ($project in $projects) {
    $destination = Join-Path $project.FullName '.obsidian'

    if (Test-Path -LiteralPath $destination) {
        Write-Warning "Already exists; skipped: $destination"
        continue
    }

    try {
        New-Item -ItemType Junction -Path $destination -Target $source -ErrorAction Stop | Out-Null
        Write-Output "Created: $destination"
    }
    catch {
        Write-Error "Could not create junction at ${destination}: $_"
        $failed = $true
    }
}

if ($failed) {
    exit 1
}

