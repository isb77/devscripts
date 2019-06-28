Param 
(
    [Parameter (Mandatory=$false, Position = 0)]
    [string] $taskName = "master",

    [Parameter (Mandatory=$false, Position = 1)]
    [string] $plugin = "Loymax.Showcase"
)


function deploy([xml] $config) 
{
    foreach($site in $Local:config.LoymaxDeployConfiguration.IisServer.Site)
    {
        Write-Host $site.Path
        foreach($application in $Local:site.Application)
        {
            Write-Host $application

            switch ($site.Path) {
                "Arm" 
                {

                }

                "Public"
                {

                }
                
                Default 
                {
                    foreach($pl in $Local:application.Plugin)
                    {      
                        
                        

                        $pluginToPath = [System.IO.Path]::combine($systemApiExtFolder, $pl.TargetPath)
                        $pluginFromPath = [System.IO.Path]::combine($newDir, $pl.PackagePath, "*.*")                        
                        
                        Write-Host "Copying files from $pluginFromPath to $pluginToPath"

                        if(!(Test-Path $pluginToPath)){                            
                            New-Item -ItemType directory -Path $pluginToPath
                        }

                        Copy-Item $pluginFromPath -Destination $pluginToPath -Recurse -Force -ErrorAction Stop
                        Write-Host "done" -ForegroundColor Green
                    }
                }
            }

        }
    }
}

function unpack([string] $packagePath)
{     
    Add-Type -assembly "system.io.compression.filesystem"
    $zip = [IO.Compression.ZipFile]::OpenRead($Local:packagePath)
    $zip.Entries | where {$_.FullName.StartsWith($Local:subDirectory,"CurrentCultureIgnoreCase")} | ForEach-Object {
        $filePath = [System.IO.Path]::combine($newDir, $_.FullName)
        if ($filePath.EndsWith("\"))
        {
            if (!(Test-Path $filePath))
            {
                New-Item -ItemType Directory -Path $filePath | Out-Null 
            }
        }
        else
        {
            $path = Split-Path -Path $filePath 
            if (!(Test-Path $path))
            {
                New-Item -ItemType Directory -Path $path | Out-Null
            }

            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$filePath", $true)
        }
    }

    $zip.Dispose()
    Write-Host "done" -ForegroundColor Green -NoNewline
	Write-Host " {$newDir}"
    return Get-Item -Path $newDir
}

$sourceFolder = $home + "\source\tasks\" + $taskName + "\Integration\Loymax.Plugins"
$targetFolder = $home + "\source\tasks\" + $taskName + "\Loymax\Kernel"
$systemApiExtFolder = $targetFolder + "\Loymax.SystemApi\bin\Extensions"
Write-Host "Source folder $sourceFolder" -ForegroundColor Green
Write-Host "Target folder $targetFolder" -ForegroundColor Green
Write-Host "SystemApi folder $systemApiExtFolder" -ForegroundColor Green


Write-Host "Trying to find $plugin plugin..."

$file = Get-ChildItem -Path $sourceFolder -Include *.nuspec -Recurse -File  -Filter "$plugin.nuspec" -Force

Write-Host $file.Directory
$settingsFile = [System.IO.Path]::combine($file.Directory, "settings.xml")


[xml]$settings = Get-Content $settingsFile  

$newDir = [System.IO.Path]::combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $newDir | Out-Null
Write-Host $newDir

Set-Location $file.Directory
nuget pack $nuspec -OutputDirectory $newDir -Version 1  | Out-Null

$packageFile = Get-ChildItem -Path $newDir -File -Filter "*.nupkg" -Force

unpack($packageFile.FullName)
deploy($settings)

#Remove-Item -Path $newDir -Force -Recurse


