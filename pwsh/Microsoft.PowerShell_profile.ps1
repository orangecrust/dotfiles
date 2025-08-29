# aliases
new-alias -name python2 -value 'C:\Program Files\Python27\python.exe'

# load custom functions
$fdir = join-path -path $PSScriptRoot -ChildPath "modules"
Get-ChildItem "$fdir/*.ps1" | %{.$_}

# load modules
$modules = gci -re $fdir -in *.psm1
foreach ($module in $modules) {
    Import-Module $module
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Import-Module PSReadLine
# enable Vim on the shell and as editor
$OnViModeChange = [scriptblock]{
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "`e[2 q"
    }
    else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[0 q"
    }
}

# Set-PsReadLineOption -EditMode Vi
# Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $OnViModeChange
#
# Black 	0 	
# Blue 	9 	
# Cyan 	11 	
# DarkBlue 	1 	
# DarkCyan 	3 	
# DarkGray 	8 	
# DarkGreen 	2 	
# DarkMagenta 	5 	
# DarkRed 	4 	
# DarkYellow 	6 	
# Gray 	7 	
# Green 	10 	
# Magenta 	13 	
# Red 	12 	
# White 	15 	
# Yellow 	14 	

#function global:prompt {
#    " "
#    $colo = 3
#    Write-Host -NoNewline -ForegroundColor $colo '░▒'
#    Write-Host -NoNewline -ForegroundColor White -BackgroundColor $colo ' '
#    $p = (convert-path .).Replace((convert-path $env:USERPROFILE), "~")
#    Write-Host -NoNewline -ForegroundColor $colo '['
#    Write-Host -NoNewline $p
#    Write-Host -NoNewline -ForegroundColor $colo ']── -'
#}
function global:prompt {
    " "
    $colo = 3
    Write-Host -NoNewline -ForegroundColor $colo '░▒'
    Write-Host -NoNewline -ForegroundColor White -BackgroundColor $colo ' '
    $p = (convert-path .).Replace((convert-path $env:USERPROFILE), "~")
    Write-Host -NoNewline -ForegroundColor White -BackgroundColor $colo $p
    Write-Host -NoNewline -ForegroundColor White -BackgroundColor $colo ' '
    Write-Host -NoNewline -ForegroundColor $colo '▒░'
}

# function global:prompt {
#     " "
#     $bg = 3
#     $fg = 0
#     $p = (convert-path .).Replace((convert-path $env:USERPROFILE), "~")
#     Write-Host -NoNewline -ForegroundColor $bg '▒'
#     Write-Host -NoNewline -BackgroundColor $bg " " $p " "
#     Write-Host -NoNewline -ForegroundColor $bg '▒░'
# }
