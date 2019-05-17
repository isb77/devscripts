# добавить параметр вызова имя ветки
# создаватьт каталог с задачей. скачивать ветку
Param
(
    
    [Parameter (Mandatory=$true, Position = 0)]
    [string] $taskName,

    [Parameter (Mandatory=$true, Position = 1)]
    [string] $branchName = $taskName,

    [Parameter (Mandatory=$true, Position = 2)]
    [AllowEmptyString()]
	[string] $integrationBranchName = "",
    
    [Parameter (Mandatory=$false, Position = 3)]    
    [bool] $buildArm=$true,

    [Parameter (Mandatory=$false, Position = 4)]
    [bool] $buildPlugins=$true,

    [Parameter (Position = 5)]
    [string] $targetFolder = ""
)

if([string]::IsNullOrWhiteSpace($targetFolder)) {    
    $targetFolder = $home + "\source\tasks\"
}
$currentLocation = Get-Location

Write-Host "Папка с задачами $targetFolder"

function Get-Repository-Branch {

    Param 
    (   
        [string] $taskName, 
        [string] $branch, 
        [string] $repo
    )

    if([string]::IsNullOrWhiteSpace($branch)) {
        $parts = ($repo -split "/")[-1]        
        Write-Host "$parts skipped"
        return $false;
    }

    Write-Host "Branch Name: $branchName $repo $build"

	$checkBranch = $(git ls-remote --exit-code --heads $repo $branch) 
    $hasBranch = $checkBranch -like "*$branch*"

    if(!$hasBranch) {
        Write-Host "Не найдена ветка $branchName" -ForegroundColor Red
        return $false;
    }
    	
    $taskFolder = [System.IO.Path]::combine($targetFolder, $taskName)
    if(!(Test-Path $taskFolder)){
        # Write-Host "Папка $branchName уже создана" -ForegroundColor Red
        # return $false
        New-Item -ItemType directory -Path $taskFolder
    }
        
    Set-Location $taskFolder    

    git clone -b $branch $repo    

    Write-Host "Location: " (Get-Location) -ForegroundColor Green       
    Write-Host "done" -ForegroundColor Blue

    return $true
}

function Install-Arm-Packages {
    Param 
    (   
        [Parameter (Position = 0)]
        [string] $taskName, 

        [Parameter (Position = 1)]
        [string] $folder = ''
    )

    if([string]::IsNullOrWhiteSpace($folder)) 
    {
        return $false
    }
       
    $sourceFolder = [System.IO.Path]::combine($targetFolder, $taskName, $folder)
    if(!(Test-Path $sourceFolder))
    {
        return $false;
    }

    Set-Location $sourceFolder

    Write-Host "Install Packages, Location: " (Get-Location) -ForegroundColor Green
    yarn install    
}

function Build-Arm {
    Param 
    (   
        [Parameter (Position = 0)]
        [string] $taskName, 

        [Parameter (Position = 1)]
        [string] $folder = '',

        [Parameter (Position = 2)]
        [ValidateSet('gulp','npm')]
        [string] $buildAgent 
    )

    if([string]::IsNullOrWhiteSpace($folder)) 
    {
        return $false
    }
       
    $sourceFolder = [System.IO.Path]::combine($targetFolder, $taskName, $folder)
    if(!(Test-Path $sourceFolder))
    {
        return $false;
    }

    Set-Location $sourceFolder

    switch ($buildAgent) {
        'gulp' {
            try
            {
                Write-Host "Build using gulp: " (Get-Location) -ForegroundColor Green
			    gulp build
            }
            catch
            {                
                Write-Host "Compilation ARM error" -ForegroundColor red            
            }
          }

        'npm' {
            try {
                Write-Host "Build using npm: " (Get-Location) -ForegroundColor Green
                npm run build
            }
            catch {
                Write-Host "Compilation ARM error" -ForegroundColor red            
            }
        }

        Default {}
    }
}


function Get-Task(){
    try
    {
        
        # Получаем исходники
        Get-Repository-Branch $taskName $branchName  "https://tfs.loymax.net/DefaultCollection/_git/Loymax"
        Get-Repository-Branch $taskName $integrationBranchName  "https://tfs.loymax.net/DefaultCollection/Loymax/_git/Integration"

        # Устанавливаем пакеты и компилируем
        Install-Arm-Packages $taskName "Loymax\ARMv2"
        Install-Arm-Packages $taskName "Loymax\ARMv3"
        Install-Arm-Packages $taskName "Integration\Loymax.Arm.Plugins"

        # Компилируем 
        if($buildArm) {
            Build-Arm $taskName "Loymax\ARMv2" "gulp"
            Build-Arm $taskName "Loymax\ARMv3" "npm"
        }

        if($buildPlugins) {
            Build-Arm $taskName "Integration\Loymax.Arm.Plugins" "gulp"
        }

        # Создаем сайт, если требуется
        $siteName = $taskName
        $taskFolder = [System.IO.Path]::combine($targetFolder, $taskName)        
        if (!(Test-Path IIS:\Sites\$siteName))
        {                
            Write-Host "creating $branchName.localhost web site ..." -ForegroundColor Yellow
    
            Write-Host "Task Folder $taskFolder" -ForegroundColor Green
            $physicalSitePath = [System.IO.Path]::combine($taskFolder, "Loymax\ARMv3\build")
            $physicalExtSystemPath = [System.IO.Path]::combine($taskFolder, "Loymax\Kernel\Loymax.SystemApi")
            $physicalPublicApiPath = [System.IO.Path]::combine($taskFolder, "Loymax\Kernel\Loymax.PublicApi")
            $physicalSystemApiPath = [System.IO.Path]::combine($taskFolder, "Loymax\Kernel\Loymax.WebSites.ExternalSystem")
    
            if(!(Test-Path $physicalSitePath)){
            	New-Item -ItemType directory -Path $physicalSitePath
            }

            Write-Host $physicalSitePath
            Write-Host $physicalSystemApiPath
            Write-Host $physicalPublicApiPath
            Write-Host $physicalExtSystemApiPath

            $hostHeader = "$siteName.localhost"        
                        
            New-Website -Name $siteName -Port 80 -PhysicalPath $physicalSitePath -IPAddress "*" -HostHeader $hostHeader -ApplicationPool "DefaultAppPool"
            New-WebApplication -Site $siteName -Name "api" -PhysicalPath $physicalSystemApiPath -ApplicationPool "DefaultAppPool"
            New-WebApplication -Site $siteName -Name "SystemApi" -PhysicalPath $physicalSystemApiPath -ApplicationPool "DefaultAppPool"
            New-WebApplication -Site $siteName -Name "PublicApi" -PhysicalPath $physicalPublicApiPath -ApplicationPool "DefaultAppPool"
            New-WebApplication -Site $siteName -Name "ExternalSystem" -PhysicalPath $physicalExtSystemPath -ApplicationPool "DefaultAppPool"

            Write-Host "created" -ForegroundColor Green

            Write-Host "Update hosts file..." -ForegroundColor Yellow -NoNewline       
            Add-Content -Encoding UTF8  C:\Windows\system32\drivers\etc\hosts "127.0.0.1    $hostHeader"

            Write-Host "done" -ForegroundColor Green                        
                    Write-Host ""
            Write-Host "Try to open http://$hostHeader"
        }
        else # Сайт уже существует, ничего не делаем
        {
            Write-Host "exist" -ForegroundColor Green
        }
               
    }
    finally
    {
        Set-Location $currentLocation
    }
}

Get-Task