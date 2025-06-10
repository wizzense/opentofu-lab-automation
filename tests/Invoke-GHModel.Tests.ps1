Describe 'Invoke-GHModel' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Invoke-GHModel.ps1')
    }

    It 'posts prompt to GitHub endpoint with token' {
        $headers = $null
        $body    = $null
        Mock Invoke-RestMethod {
            param($Uri,$Method,$Headers,$Body)
            $headers = $Headers
            $body    = $Body
            @{ choices = @(@{ message = @{ content = 'response text' } }) }
        }
        $env:GITHUB_MODEL_TOKEN = 'testtoken'
        $result = Invoke-GHModel -Model 'test-model' -Prompt 'hello'

        $headers.Authorization | Should -Be 'Bearer testtoken'
        $headers.Accept | Should -Be 'application/json'
        ($body | ConvertFrom-Json).prompt | Should -Be 'hello'
        $result | Should -Be 'response text'
    }

    It 'includes parameters when provided' {
        $captured = $null
        Mock Invoke-RestMethod {
            param($Uri,$Method,$Headers,$Body)
            $captured = $Body
            @{ choices = @(@{ message = @{ content = 'x' } }) }
        }
        $env:GITHUB_MODEL_TOKEN = 'tok'
        Invoke-GHModel -Model 'model' -Prompt 'p' -Parameters @{temperature=0.1}
        (($captured | ConvertFrom-Json).parameters.temperature) | Should -Be 0.1
    }
}
