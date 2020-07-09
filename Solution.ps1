# Удаляет все папки obj и bin
Param
(

	[Parameter(mandatory = $true)]
	[ValidateSet('clear','build', 'rebuild', 'rebuild-arm', 'init')]
	[string] $command = ""
)

function Delete
{
    Param 
    (   
        [string] $path 
    )

    if(Test-Path $path){
        Remove-Item -Path $path -Recurse -Force
        Write-Host $path " removed" -ForegroundColor Green
    }    

}

if((Test-Path .\Kernel\loymax.sln) -eq $false){
    Write-Host "It is not solution folder" -ForegroundColor Red
    return
}

$installPath = &"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -version 16.0 -property installationpath
$currentFolder = Location

switch ($command) {
    "init" {
        Remove-Bin-Obj
        Delete ARMv2\build               
        Delete ARMv2\node_modules        
        Delete ARMv3\build        
        Delete ARMv3\node_modules

        cd .\Kernel
        .\scripts cs-update
        cd ..
        
        nuget restore Kernel
                
        Import-Module (Join-Path $installPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
        Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation
        
        msbuild .\Kernel\loymax.sln -clp:"Summary;Verbosity=minimal" -m -t:build

        cd .\ARMv3
        npm run pi
        npm run build
        cd ..
    }

    "clear" {
	Remove-Bin-Obj
	}

    "build" {
        Import-Module (Join-Path $installPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
        Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation
                
        msbuild .\Kernel\loymax.sln -clp:"Summary;Verbosity=minimal" -m -t:build
        #Remove-Module "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    }

    "rebuild" {
        Remove-Bin-Obj
        nuget restore Kernel
                
        Import-Module (Join-Path $installPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
        Enter-VsDevShell -VsInstallPath $installPath -SkipAutomaticLocation
        
        msbuild .\Kernel\loymax.sln -clp:"Summary;Verbosity=minimal" -m -t:build
    }

    "rebuild-arm" {
        Write-Host "Rebuild started..."                 
     
        Delete ARMv2\build               
        Delete ARMv2\node_modules        
        Delete ARMv3\build        
        Delete ARMv3\node_modules
        
        cd ARMv3
        npm run pi
        npm run build

        Write-Host "Rebuild completed"                 
    }
}

cd $currentFolder

