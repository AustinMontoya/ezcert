. ".\utils.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\New-LocalClientCert.ps1"
$ezcertExecutablePath = "$here\..\..\ezcert\bin\Release\ezcert.exe"

Describe "New-LocalClientCert" {
  It "Generates a new client cert and auto-imports" {
    New-LocalCA -Name "testCaForClient" -Password "unicorns" -OutputFileName "testCaForClient.pfx" -AutoImport $false 
    New-LocalClientCert -Name "testClientCert" -Password "password" -OutputFileName "testClientCert.pfx" -CaPath "$here\..\testCaForClient.pfx" -CaPassword "unicorns" -UseDefaultCa $false

    Test-Path "$here\..\testClientCert.pfx" | Should Be $true

    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.subject -eq "CN=testClientCert" }
    $cert | Should Not Be $null
  }

  It "Does not auto-import when set to false" {
    New-LocalCA -Name "testCaForClientNoImport" -Password "unicorns" -outputFileName "testCaForClientNoImport.pfx" -AutoImport $false
    New-LocalClientCert -Name "testClientCertNoImport" -Password "password" -OutputFileName "testClientCertNoImport.pfx" -CaPath "$here\..\testCaForClientNoImport.pfx" -CaPassword "unicorns" -UseDefaultCa $false -AutoImport $false
  
    Test-Path "$here\..\testClientCertNoImport.pfx" | Should Be $true

    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.subject -eq "CN=testCaForClientNoImport" }
    $cert | Should Be $null
  }

  # How do we test default args without messing up the machine state?
}