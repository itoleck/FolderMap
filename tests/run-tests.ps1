[CmdletBinding()]
param(
    [switch]$SkipGui,
    [string]$ScreenshotPath
)

$ErrorActionPreference = 'Stop'
if (-not [Environment]::Is64BitProcess -or $PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run these tests with 64-bit Windows PowerShell (powershell.exe), not pwsh.'
}
$assemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
if (-not (Test-Path -LiteralPath $assemblyPath)) {
    throw 'Build first: .\build.ps1'
}

Add-Type -AssemblyName System.Windows.Forms
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $assemblyPath).Path)
if ($assembly.GetName().ProcessorArchitecture -ne 'Amd64') { throw 'Assembly is not AMD64.' }
$framework = @($assembly.GetCustomAttributes($false) | Where-Object { $_ -is [Runtime.Versioning.TargetFrameworkAttribute] })[0]
if ($framework.FrameworkName -ne '.NETFramework,Version=v4.8') { throw 'Unexpected target framework metadata.' }

# ILAsm can accept method bodies whose stack/signatures fail only at JIT time.
$prepared = 0
$flags = [Reflection.BindingFlags]'DeclaredOnly,Public,NonPublic,Instance,Static'
foreach ($type in $assembly.GetTypes()) {
    foreach ($method in @($type.GetMethods($flags)) + @($type.GetConstructors($flags))) {
        if (-not $method.IsAbstract -and -not $method.ContainsGenericParameters) {
            try {
                [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
            } catch {
                throw "JIT validation failed for $($type.FullName).$($method.Name): $_"
            }
            $prepared++
        }
    }
}
Write-Host "AMD64 architecture and .NET 4.8 metadata verified; $prepared IL methods JIT-compiled."

& (Join-Path $PSScriptRoot 'scanner.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'parallel-scanner.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'elevation.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'usn.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cache-store.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cache-delta.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cache-ancestors.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cache-policy.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cached-scanner.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'cache-refresh.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'treemap.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'tiling.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'options.tests.ps1') -AssemblyPath $assemblyPath
& (Join-Path $PSScriptRoot 'explorer.tests.ps1') -AssemblyPath $assemblyPath
if ($SkipGui) {
    Write-Host 'GUI tests explicitly skipped (-SkipGui).'
} else {
    & (Join-Path $PSScriptRoot 'gui.tests.ps1') -AssemblyPath $assemblyPath -ScreenshotPath $ScreenshotPath
    & (Join-Path $PSScriptRoot 'process.tests.ps1') -AssemblyPath $assemblyPath
}
Write-Host 'All requested FolderMap checks passed.'
