Function Set-AksConfigValues {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$TemplatePath,

        [Parameter(Mandatory)]
        [PSObject[]]$Values
    )

    $TemplateContent = Get-Content -Path $TemplatePath

    Foreach ( $ParameterObject in $Values ) {
        $DescriptionPattern = '{{{0}Description}}' -f $ParameterObject.Name

        # Nicer formatting for multi-line descriptions
        $FormattedDesc = $ParameterObject.Description -replace "\n", "`n`t"
        $TemplateContent = $TemplateContent.ForEach('Replace', $DescriptionPattern, $FormattedDesc)

        $TypePattern = '{{{0}ValueType}}' -f $ParameterObject.Name
        $TemplateContent = $TemplateContent.ForEach('Replace', $TypePattern, $ParameterObject.Type)

        $ValidValuesPattern = '{{{0}ValidValues}}' -f $ParameterObject.Name
        $TemplateContent = $TemplateContent.ForEach('Replace', $ValidValuesPattern, $ParameterObject.ValidValues)

        # Resolve expressions to their value because expressions are not allowed in PowerShell data files
        If ( $ParameterObject.DefaultValue -match '^"\$' ) {
            [string]$DefaultValue = '"{0}"' -f (Invoke-Expression $ParameterObject.DefaultValue)
        }
        Else {
            [string]$DefaultValue = $ParameterObject.DefaultValue
        }
        $DefaultValuePattern = '{{{0}DefaultValue}}' -f $ParameterObject.Name
        $TemplateContent = $TemplateContent.ForEach('Replace', $DefaultValuePattern, $DefaultValue)
    }
    $TemplateContent
}
