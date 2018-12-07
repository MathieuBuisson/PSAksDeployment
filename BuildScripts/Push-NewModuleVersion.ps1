Param (
    [Parameter(Mandatory)]
    [ValidateScript( { ($_ -as [System.Version]) -as [bool] })]
    [string]$NewVersion,

    [Parameter(Mandatory=$False)]
    [string]$ProjectName = $Env:SYSTEM_TEAMPROJECT,

    [Parameter(Mandatory=$False)]
    [string]$GithubPAT = $Env:GITHUB_PAT,

    [Parameter(Mandatory=$False)]
    [string]$Username = $Env:github_user,

    [Parameter(Mandatory=$False)]
    [string]$EmailAddress = $Env:EMAIL_ADDRESS,

    [Parameter(Mandatory=$False)]
    [string]$GitBranch = $Env:BUILD_SOURCEBRANCHNAME
)

# Putting git commands in Try{} because git.exe always writes to error stream
Try {
    git config user.email "$EmailAddress"
    git config user.name "$Username"
    git config core.autocrlf true
    Write-Host "Checking out git branch [$GitBranch]"
    git checkout -f $GitBranch
}
Catch {
    Write-Host $_.Exception.Message
}

$ModuleName = 'PSAksDeployment'
$ManifestPath = "./$ModuleName/$ModuleName.psd1"
$ManifestContent = Get-Content -Path $ManifestPath
$VersionRegex = "ModuleVersion\s=\s'(?<ModuleVersion>\S+)'" -as [regex]
$CurrentVersion = $VersionRegex.Match($ManifestContent).Groups['ModuleVersion'].Value
Write-Host "Current version in the manifest [$CurrentVersion]"

$ManifestContent -replace $CurrentVersion, $NewVersion | Set-Content -Path $ManifestPath -Force
Write-Host "Updated version in the manifest to [$NewVersion]"

Try {
    git status
    git add $ManifestPath
    git commit -m "Commit CI pipeline changes ***NO_CI***"
    $GitUrl = 'https://{0}@github.com/{1}/{2}.git' -f $GithubPAT, $Username, $ProjectName
    git push $GitUrl HEAD:$GitBranch
}
Catch {
    Write-Host $_.Exception.Message
}
