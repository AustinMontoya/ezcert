$msBuildPath = $MSBUILD_PATH
if (!$msBuildPath) {
  $msBuildPath = 'C:\Program Files (x86)\MSBuild\14.0\Bin'
}

$args = '/p:Configuration=Release'
iex "& '$msBuildPath\msbuild.exe' $args"

$outputFolder = '.\artifacts'

if (Test-Path $outputFolder) {
  rm -r -force $outputFolder
}

mkdir $outputFolder
cp "$PWD\ezcert\bin\Release\*" $outputFolder
cp -recurse "$PWD\powershell\*" $outputFolder

$workDir = (Get-Item -Path $PWD).FullName
$packageDest = "$workDir\package.zip"

if (Test-Path $packageDest) {
  rm -r -force $packageDest
}

Add-Type -A 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::CreateFromDirectory("$workDir\artifacts", $packageDest)
