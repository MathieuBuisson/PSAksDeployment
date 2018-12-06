Param (
    [Parameter(Mandatory)]
    [ValidateSet('Unit', 'System')]
    [string]$TestSuite
)

$TestParams = @{
    Script     = './Tests/{0}' -f $TestSuite
    Strict     = $True
    OutputFile = '{0}/{1}TestResults.xml' -f $Env:COMMON_TESTRESULTSDIRECTORY, $TestSuite
    PassThru   = $True
}
$PesterOutput = Invoke-Pester @TestParams

$FailedTestCount = $PesterOutput.FailedCount
If ( $FailedTestCount -gt 0 ) {
    Throw "$($FailedTestCount) test(s) failed. Aborting this job."
}
