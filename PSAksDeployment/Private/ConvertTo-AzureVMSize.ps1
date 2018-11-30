Function ConvertTo-AzureVMSize {
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$SizeDisplayName
    )

    Switch ($SizeDisplayName) {
        'B_2vCPU_8GB' { return 'Standard_B2ms' }
        'B_4vCPU_16GB' { return 'Standard_B4ms' }
        'D_2vCPU_8GB' { return 'Standard_D2s_v3' }
        'D_4vCPU_16GB' { return 'Standard_D4s_v3' }
        'D_8vCPU_32GB' { return 'Standard_D8s_v3'}
        'E_2vCPU_16GB' { return 'Standard_E2s_v3' }
        'E_4vCPU_32GB' { return 'Standard_E4s_v3' }
        'F_2vCPU_4GB' { return 'Standard_F2s_v2' }
        'F_4vCPU_8GB' { return 'Standard_F4s_v2' }
        'DS_2vCPU_7GB' { return 'Standard_DS2_v2' }
        'DS_4vCPU_14GB' { return 'Standard_DS3_v2' }
    }
}
