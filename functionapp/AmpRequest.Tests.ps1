BeforeAll {
    . $PSScriptRoot/AMPRequest.ps1
    $simpleRequestExample = Get-Content -Path . $PSScriptRoot/test-files/RequestExample-01.json
}


Describe "AmpRequest Submit Method" {
    Context "simple request" {
        It 'should return a job object' {
            $testRequestObject = [AmpRequest]::new($simpleRequestExample) | Should -Be 
        }
    }
}