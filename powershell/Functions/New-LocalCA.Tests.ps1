# TODO: test password
# TODO: remove cert on teardown
# TODO: test whether imported cert can be exported

. ".\utils.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\New-LocalCA.ps1"

$ezcertExecutablePath = "$here\..\..\ezcert\bin\Release\ezcert.exe"

Describe "New-LocalCA" {
  It "Generates a new CA and auto-imports" {
    New-LocalCA -Name "testCa" -Password "unicorns" -outputFileName "testCa.pfx"
    Test-Path -Path "$here\..\testCa.pfx" | Should Be $true
    Sleep 5
    $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.subject -eq "CN=testCa" }
    $cert | Should Not Be $null
    
  }

  It "Does not auto-import when set to false" {
    New-LocalCA -Name "testCaNoImport" -Password "unicorns" -outputFileName "testCaNoImport.pfx" -AutoImport $false
    Test-Path -Path "$here\..\testCaNoImport.pfx" | Should Be $true
    Sleep 5
    $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.subject -eq "CN=testCaNoImport" }
    $cert | Should Be $null
  }

  # How do we test default args without messing up the machine state?
}