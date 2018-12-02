Function Save-PSAksPrerequisite {
<#
.SYNOPSIS
    Downloads an installation file or package and saves it to the specified folder.

.DESCRIPTION
    Downloads an installation file or package and saves it to the specified folder.
    If the downloaded file is a .zip file, it extracts its content.

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [ValidateScript({ ($_ -as [uri]).IsAbsoluteUri })]
        [string]$Uri,

        [Parameter(Mandatory, Position=1)]
        [string]$Path
    )

    $FileName = ($Uri -split '/' )[-1]
    $TempPath = Join-Path -Path $env:TEMP -ChildPath $FileName
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Invoke-WebRequest -Uri $Uri -OutFile $TempPath

    If ( -not(Test-Path -Path $TempPath -PathType Leaf) ) {
        Throw "A file cannot be found at expected download location : $TempPath"
    }
    Write-ConsoleLog "Successfully downloaded file to : [$TempPath]"

    $FileItem = Get-ChildItem -Path $TempPath
    $FileBaseName = $FileItem.BaseName
    $FileItemExtension = $FileItem.Extension

    # Extracting the file if it is a .zip
    If ( $FileItemExtension -eq '.zip' ) {
        $ExtractFolder = Join-Path -Path $env:TEMP -ChildPath $FileBaseName
        $ExtractParams = @{
            Path            = $TempPath
            DestinationPath = $ExtractFolder
            Force           = $True
            ErrorAction     = 'Stop'
        }
        Write-ConsoleLog "Extracting into [$ExtractFolder]"
        Expand-Archive @ExtractParams
    }
    Else {
        $ExtractFolder = $Null
    }

    $ItemsToCopy = If ( $ExtractFolder ) {Get-ChildItem -Path $ExtractFolder -File -Filter '*.exe' -Recurse} Else {$FileItem}
    Foreach ( $Item in $ItemsToCopy ) {
        $Item | Unblock-File -Confirm:$False
        $CopyParams = @{
            Path        = $Item.FullName
            Destination = $Path
            Force       = $True
            Confirm     = $False
            ErrorAction = 'Stop'
        }
        Write-ConsoleLog "Copying [$($Item.Name)] to [$Path]"
        Copy-Item @CopyParams
    }
    Remove-Item -Path $TempPath -Force
}
