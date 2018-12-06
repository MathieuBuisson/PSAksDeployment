Param (
    [Parameter(Position=0, Mandatory=$False)]
    [string]$ProjectName = $Env:SYSTEM_TEAMPROJECT,

    [Parameter(Position=1, Mandatory=$False)]
    [string]$GithubPAT = $Env:GITHUB_PAT,

    [Parameter(Position=1, Mandatory=$False)]
    [string]$Username = $Env:github_user,
    
    [Parameter(Position=2, Mandatory=$False)]
    [string]$EmailAddress = $Env:EMAIL_ADDRESS
)

$ErrorActionPreference = 'Stop'

& git config user.email "$EmailAddress" 2>&1
& git config user.name "$Username" 2>&1
& git config core.autocrlf true 2>&1
& git add -A 2>&1
& git commit -m "Commit CI pipeline changes ***NO_CI***" 2>&1

$GitUrl = 'https://{0}@github.com/{1}/{2}.git' -f $GithubPAT, $Username, $ProjectName
& git push $GitUrl HEAD:master 2>&1
Write-Host 'CI changes pushed to repository'
