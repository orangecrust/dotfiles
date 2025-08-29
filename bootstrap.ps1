# install scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras

# install rotz
scoop bucket add volllly https://github.com/volllly/scoop-bucket
scoop install volllly/rotz
