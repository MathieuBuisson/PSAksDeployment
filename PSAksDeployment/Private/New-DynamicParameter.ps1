<#
.SYNOPSIS
	Helper function to simplify creating dynamic parameters

.NOTES
    Credits to beatcracker :
        https://beatcracker.wordpress.com/2015/08/10/dynamic-parameters-validateset-and-enums/

.PARAMETER Name
	Name of the dynamic parameter

.PARAMETER Type
	Type for the dynamic parameter.  Default is string

.PARAMETER Alias
	If specified, one or more aliases to assign to the dynamic parameter

.PARAMETER Mandatory
	If specified, set the Mandatory attribute for this dynamic parameter

.PARAMETER Position
	If specified, set the Position attribute for this dynamic parameter

.PARAMETER HelpMessage
	If specified, set the HelpMessage for this dynamic parameter

.PARAMETER DontShow
	If specified, set the DontShow for this dynamic parameter.
	This is the new PowerShell 4.0 attribute that hides parameter from tab-completion.
	http://www.powershellmagazine.com/2013/07/29/pstip-hiding-parameters-from-tab-completion/

.PARAMETER ValueFromPipeline
	If specified, set the ValueFromPipeline attribute for this dynamic parameter

.PARAMETER ValueFromPipelineByPropertyName
	If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

.PARAMETER ValueFromRemainingArguments
	If specified, set the ValueFromRemainingArguments attribute for this dynamic parameter

.PARAMETER ParameterSetName
	If specified, set the ParameterSet attribute for this dynamic parameter. By default parameter is added to all parameters sets.

.PARAMETER AllowNull
	If specified, set the AllowNull attribute of this dynamic parameter

.PARAMETER AllowEmptyString
	If specified, set the AllowEmptyString attribute of this dynamic parameter

.PARAMETER AllowEmptyCollection
	If specified, set the AllowEmptyCollection attribute of this dynamic parameter

.PARAMETER ValidateNotNull
	If specified, set the ValidateNotNull attribute of this dynamic parameter

.PARAMETER ValidateNotNullOrEmpty
	If specified, set the ValidateNotNullOrEmpty attribute of this dynamic parameter

.PARAMETER ValidateRange
	If specified, set the ValidateRange attribute of this dynamic parameter

.PARAMETER ValidateLength
	If specified, set the ValidateLength attribute of this dynamic parameter

.PARAMETER ValidatePattern
	If specified, set the ValidatePattern attribute of this dynamic parameter

.PARAMETER ValidateScript
	If specified, set the ValidateScript attribute of this dynamic parameter

.PARAMETER ValidateSet
	If specified, set the ValidateSet attribute of this dynamic parameter

.PARAMETER Dictionary
	If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary.
	Appropriate for custom dynamic parameters creation.

	If not specified, create and return a RuntimeDefinedParameterDictionary
	Appropriate for a simple dynamic parameter creation.
#>
Function New-DynamicParameter {
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'DynamicParameter')]
	Param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[System.Type]$Type = [int],

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string[]]$Alias,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$Mandatory,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[int]$Position,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string]$HelpMessage,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$DontShow,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromPipeline,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromPipelineByPropertyName,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValueFromRemainingArguments,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[string]$ParameterSetName = '__AllParameterSets',

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowNull,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowEmptyString,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$AllowEmptyCollection,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValidateNotNull,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[switch]$ValidateNotNullOrEmpty,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateCount,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateRange,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateCount(2,2)]
		[int[]]$ValidateLength,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string]$ValidatePattern,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ValidateScript,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[string[]]$ValidateSet,

		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
			if(!($_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary]))
			{
				Throw 'Dictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object'
			}
			$true
		})]
		$Dictionary = $false,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
		[switch]$CreateVariables,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
			# System.Management.Automation.PSBoundParametersDictionary is an internal sealed class,
			# so one can't use PowerShell's '-is' operator to validate type.
			if($_.GetType().Name -ne 'PSBoundParametersDictionary')
			{
				Throw 'BoundParameters must be a System.Management.Automation.PSBoundParametersDictionary object'
			}
			$true
		})]
		$BoundParameters
	)

	Begin
	{
		Write-Verbose 'Creating new dynamic parameters dictionary'
		$InternalDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

		Write-Verbose 'Getting common parameters'
		function _temp { [CmdletBinding()] Param() }
		$CommonParameters = (Get-Command _temp).Parameters.Keys
	}

	Process
	{
		if($CreateVariables)
		{
			Write-Verbose 'Creating variables from bound parameters'
			Write-Debug 'Picking out bound parameters that are not in common parameters set'
			$BoundKeys = $BoundParameters.Keys | Where-Object { $CommonParameters -notcontains $_ }

			foreach($Parameter in $BoundKeys)
			{
				Write-Debug "Setting existing variable for dynamic parameter '$Parameter' with value '$($BoundParameters.$Parameter)'"
				Set-Variable -Name $Parameter -Value $BoundParameters.$Parameter -Scope 1 -Force
			}
		}
		else
		{
			Write-Verbose 'Looking for cached bound parameters'
			Write-Debug 'More info: https://beatcracker.wordpress.com/2014/12/18/psboundparameters-pipeline-and-the-valuefrompipelinebypropertyname-parameter-attribute'
			$StaleKeys = @()
			$StaleKeys = $PSBoundParameters.GetEnumerator() |
						ForEach-Object {
							if($_.Value.PSobject.Methods.Name -match '^Equals$')
							{
								# If object has Equals, compare bound key and variable using it
								if(!$_.Value.Equals((Get-Variable -Name $_.Key -ValueOnly -Scope 0)))
								{
									$_.Key
								}
							}
							else
							{
								# If object doesn't has Equals (e.g. $null), fallback to the PowerShell's -ne operator
								if($_.Value -ne (Get-Variable -Name $_.Key -ValueOnly -Scope 0))
								{
									$_.Key
								}
							}
						}
			if($StaleKeys)
			{
				[string[]]"Found $($StaleKeys.Count) cached bound parameters:" +  $StaleKeys | Write-Debug
				Write-Verbose 'Removing cached bound parameters'
				$StaleKeys | ForEach-Object {[void]$PSBoundParameters.Remove($_)}
			}

			# Since we rely solely on $PSBoundParameters, we don't have access to default values for unbound parameters
			Write-Verbose 'Looking for unbound parameters with default values'

			Write-Debug 'Getting unbound parameters list'
			$UnboundParameters = (Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters.GetEnumerator()  |
										# Find parameters that are belong to the current parameter set
										Where-Object { $_.Value.ParameterSets.Keys -contains $PsCmdlet.ParameterSetName } |
											Select-Object -ExpandProperty Key |
												# Find unbound parameters in the current parameter set
												Where-Object { $PSBoundParameters.Keys -notcontains $_ }

			# Even if parameter is not bound, corresponding variable is created with parameter's default value (if specified)
			Write-Debug 'Trying to get variables with default parameter value and create a new bound parameter''s'
			$tmp = $null
			foreach($Parameter in $UnboundParameters)
			{
				$DefaultValue = Get-Variable -Name $Parameter -ValueOnly -Scope 0
				if(!$PSBoundParameters.TryGetValue($Parameter, [ref]$tmp) -and $DefaultValue)
				{
					$PSBoundParameters.$Parameter = $DefaultValue
					Write-Debug "Added new parameter '$Parameter' with value '$DefaultValue'"
				}
			}

			if($Dictionary)
			{
				Write-Verbose 'Using external dynamic parameter dictionary'
				$DPDictionary = $Dictionary
			}
			else
			{
				Write-Verbose 'Using internal dynamic parameter dictionary'
				$DPDictionary = $InternalDictionary
			}

			Write-Verbose "Creating new dynamic parameter: $Name"

			# Shortcut for getting local variables
			$GetVar = {Get-Variable -Name $_ -ValueOnly -Scope 0}

			# Strings to match attributes and validation arguments
			$AttributeRegex = '^(Mandatory|Position|ParameterSetName|DontShow|HelpMessage|ValueFromPipeline|ValueFromPipelineByPropertyName|ValueFromRemainingArguments)$'
			$ValidationRegex = '^(AllowNull|AllowEmptyString|AllowEmptyCollection|ValidateCount|ValidateLength|ValidatePattern|ValidateRange|ValidateScript|ValidateSet|ValidateNotNull|ValidateNotNullOrEmpty)$'
			$AliasRegex = '^Alias$'

			Write-Debug 'Creating new parameter''s attirubutes object'
			$ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute

			Write-Debug 'Looping through the bound parameters, setting attirubutes...'
			switch -regex ($PSBoundParameters.Keys)
			{
				$AttributeRegex
				{
					Try
					{
						$ParameterAttribute.$_ = . $GetVar
						Write-Debug "Added new parameter attribute: $_"
					}
					Catch
					{
						$_
					}
					continue
				}
			}

			if($DPDictionary.Keys -contains $Name)
			{
				Write-Verbose "Dynamic parameter '$Name' already exist, adding another parameter set to it"
				$DPDictionary.$Name.Attributes.Add($ParameterAttribute)
			}
			else
			{
				Write-Verbose "Dynamic parameter '$Name' doesn't exist, creating"

				Write-Debug 'Creating new attribute collection object'
				$AttributeCollection = New-Object -TypeName Collections.ObjectModel.Collection[System.Attribute]

				Write-Debug 'Looping through bound parameters, adding attributes'
				switch -regex ($PSBoundParameters.Keys)
				{
					$ValidationRegex
					{
						Try
						{
							$ParameterOptions = New-Object -TypeName "System.Management.Automation.${_}Attribute" -ArgumentList (. $GetVar) -ErrorAction Stop
							$AttributeCollection.Add($ParameterOptions)
							Write-Debug "Added attribute: $_"
						}
						Catch
						{
							$_
						}
						continue
					}

					$AliasRegex
					{
						Try
						{
							$ParameterAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList (. $GetVar) -ErrorAction Stop
							$AttributeCollection.Add($ParameterAlias)
							Write-Debug "Added alias: $_"
							continue
						}
						Catch
						{
							$_
						}
					}
				}

				Write-Debug 'Adding attributes to the attribute collection'
				$AttributeCollection.Add($ParameterAttribute)

				Write-Debug 'Finishing creation of the new dynamic parameter'
				$Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)

				Write-Debug 'Adding dynamic parameter to the dynamic parameter dictionary'
				$DPDictionary.Add($Name, $Parameter)
			}
		}
	}

	End
	{
		if(!$CreateVariables -and !$Dictionary)
		{
			Write-Verbose 'Writing dynamic parameter dictionary to the pipeline'
			$DPDictionary
		}
	}
}