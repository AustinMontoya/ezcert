. ".\utils.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Initialize-ClientCertConfig.ps1"
$ezcertExecutablePath = "$here\..\..\ezcert\bin\Release\ezcert.exe"

Describe "Initialize-ClientCertConfig" {
  It "Modifies the file at the provided path" {
    $tempSourcePath = "TestData\web.config"
    $tempDestPath = "$env:TEMP\web.config"
    cp -force $tempSourcePath $tempDestPath
    
    Initialize-ClientCertConfig -Path $tempDestPath
    
    [xml]$doc = Get-Content $tempDestPath
    $el = $doc.getElementsByTagName("access")
    $el.sslFlags | Should Be "Ssl,SslRequireCert,SslNegotiateCert"
  }

  # How do we test finding the config in the global location?
}