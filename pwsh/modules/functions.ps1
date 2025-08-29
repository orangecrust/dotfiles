function g{
    param(
        [Parameter(Mandatory=$true)]$search_str
    )
    rg --vimgrep $search_str | nvim -c cb! -c copen -
}

function refresh{
    try{
        $proj = ((split-path -leaf $env:PROJECT_ROOT) -split '_val')[0]
        $proj = ((split-path -leaf $env:PROJECT_ROOT) -split '-val')[0]
        unpyval $proj
        pyval $proj
    }
    catch{"no project to refresh"}
}

function cdval{
    param(
        [Parameter(Mandatory=$false)]$proj
    )

    set-location -path c:/validation/projects
    if($proj){
        $proj_nounder = $proj -replace '_',''
        $proj_nounder = $proj_nounder -replace '-',''
        $path_under = (-join($proj_nounder,"/python/",$proj,"_val"))
        $path_dash = (-join($proj_nounder,"/python/",$proj,"-val"))
        if(Test-Path $path_under){
            cd $path_under
        }
        elseif(Test-Path $path_dash){
            cd $path_dash
        }
        else{
            "invalid project path " + $path_under
        }
    }
}

function rr{
    if(Test-Path(-join($env:project_root, "/launch_server.py"))){
        refresh && py $env:project_root/launch_server.py
    }
    else{
        refresh && py $env:project_root/scripts/launch_server.py
    }
}

function cdproj{
    cd $env:project_root
}

function cdfw{
    cd $env:proj_framework
}

function lg{
    lazygit
}

function lgfw{
    cdfw && lazygit
}

function lgproj{
    cdproj && lazygit
}

function cdfzf{
    fzf | Convert-Path | Split-Path -Parent | cd
}

function pyval{
    # parse project parameter
    param(
        [Parameter(Mandatory=$true)]$proj
    )

    # change to project directory
    cdval $proj
    $proj_under = $proj -replace '-','_'

    # venv dir
    if(Test-Path "venv"){
        $venv_dir = "venv"
    }
    else{
        $venv_dir = ".venv"
    }

    # env dir
    if(Test-Path "env"){
        $env_dir = "env"
    }
    else{
        $env_dir = join-path -path ($proj_under + "_val") -ChildPath "env"
    }

    # expand environment vars

    # activate venv
    $activate = get-item (join-path -path ("./" + $venv_dir) -ChildPath "scripts" "activate.ps1")
    & $activate

    # load project .env
    $projenv = get-item (join-path -path ("./" + $env_dir) -ChildPath (-join($proj_under , "_val.env")))
    Set-DotEnv $projenv

    # # load station .env
    # $stationenv = get-item (join-path -path $valpath -ChildPath "env" "station" (-join($proj,"_val_env_",$env:COMPUTERNAME,".env")))
    # Set-DotEnv $stationenv
    $stationenv = get-item (join-path -path ("./" + $env_dir) -ChildPath "station" (-join($proj_under,"_val_",$env:COMPUTERNAME,".env")))
    Set-DotEnv $stationenv

    cdval $proj
}

function unpyval{
    # parse project parameter
    param(
        [Parameter(Mandatory=$true)]$proj
    )

    # remove dotenv files
    Remove-DotEnv

    # deactivate
    cdval $proj

    # venv dir
    if(Test-Path "venv"){
        $venv_dir = "venv"
    }
    else{
        $venv_dir = ".venv"
    }

    cd (-join($venv_dir, "/scripts"))
    deactivate

    # activate venv
    cd ~
}

function title{
    param(
        [Parameter(Mandatory=$true)]$name
    )
    $Host.UI.RawUI.WindowTitle = $name
}

function rn {
    param (
        [string]$server_addr = 'sshore@auslab05q461',
        [int]$nvim_port = 6666,
        [int]$ssh_port = 4567
    )

    Write-Host "server address: $server_addr"
    Write-Host "neovim port: $nvim_port"
    Write-Host "ssh port: $ssh_port"

    ssh -t -L localhost:$ssh_port`:localhost:$nvim_port sshore@auslab05q461 "cd C:\validation\Projects\Lesh\python\lesh-val && .\.venv\Scripts\activate && nvim --headless --listen localhost:$nvim_port" &; start-sleep 0.75; nvim --remote-ui --server localhost:$ssh_port
}

