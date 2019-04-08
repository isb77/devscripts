# добавить параметр вызова имя ветки
# создаватьт каталог с задачей. скачивать ветку
Param
(
    [Parameter (Mandatory=$true, HelpMessage="Введите название ветки репозитория Loymax")]
    [string] $branchName,

    [Parameter (Mandatory=$true, HelpMessage="Введите название ветки репозитория Integration")]
	[string] $integrationBranchName,
    
    [Parameter (Mandatory=$true, HelpMessage="Для сборки ARM введите любое значение")]    
    [bool] $buildArm=$false,

    [Parameter (Mandatory=$true, HelpMessage="Для сборки ARM плагинов введите любое значение")]
    [bool] $buildPlugins=$false
)

$targetFolder = "C:\Users\i.bondarenko\source\tasks_tests2"
$currentLocation = Get-Location


function Get-Repository-Branch {

    Param 
    (    
        [string] $branch, 
        [string] $repo,
        [bool] $build,
        [string] $nameOfArmFolder
    )

    Write-Host "Branch Name: $branchName $repo $build"

	$checkBranch = $(git ls-remote --exit-code --heads $repo $branch) 
    $hasBranch = $checkBranch -like "*$branch*"

    if(!$hasBranch) {
        Write-Host "Не найдена ветка $branchName" -ForegroundColor Red
        return $false
    }
    	
    $taskFolder = [System.IO.Path]::combine($targetFolder, $branch)
    if(!(Test-Path $taskFolder)){
        # Write-Host "Папка $branchName уже создана" -ForegroundColor Red
        # return $false
        New-Item -ItemType directory -Path $taskFolder
    }
    
    Set-Location $taskFolder

    git clone -b $branch $repo    

    Write-Host "Location: " -NoNewLine
    Write-Host $currentLocation -ForegroundColor Green
   
    Set-Location $nameOfArmFolder
    Write-Host "Build $nameOfArmFolder..." -ForegroundColor Blue    
    yarn install

	if($build) 
	{
		try
		{
			gulp build
		}
		catch
		{
			Write-Host "Compilation ARM error" -ForegroundColor red            
		}
	}	    
    Write-Host "done" -ForegroundColor Blue

    return $true;
}

function Get-Task(){
    try
    {

        Write-Host "Get-Repository-Branch $branchName  https://tfs.loymax.net/DefaultCollection/_git/Loymax $buildArm"
      
        $loymax = Get-Repository-Branch $branchName  "https://tfs.loymax.net/DefaultCollection/_git/Loymax" $buildArm "Loymax\ARMv2"
        $integration = Get-Repository-Branch $integrationBranchName  "https://tfs.loymax.net/DefaultCollection/Loymax/_git/Integration" $buildPlugins  "Integration\Loymax.Arm.Plugins"

        # Создаем сайт, если требуется
        $siteName = $branchName
        if($loymax) {
            if (!(Test-Path IIS:\Sites\$siteName))
            {        
                Write-Host "creating $branchName.localhost web site ..." -ForegroundColor Yellow
        
                $physicalSitePath = [System.IO.Path]::combine($taskFolder, "Loymax\ARMv2\build")
                $physicalAppPath = [System.IO.Path]::combine($taskFolder, "Loymax\Kernel\Loymax.SystemApi")
        
	            #if(!(Test-Path $physicalSitePath)){
	            #	New-Item -ItemType directory -Path $physicalSitePath
	            #}

                Write-Host $physicalSitePath
                Write-Host $physicalAppPath

                $hostHeader = "$siteName.localhost"        
                         
                New-Website -Name $siteName -Port 80 -PhysicalPath $physicalSitePath -IPAddress "*" -HostHeader $hostHeader -ApplicationPool "DefaultAppPool"
                New-WebApplication -Site $siteName -Name "api" -PhysicalPath $physicalAppPath -ApplicationPool "DefaultAppPool"

                Write-Host "created" -ForegroundColor Green

                Write-Host "Update hosts file..." -ForegroundColor Yellow -NoNewline       
                ac -Encoding UTF8  C:\Windows\system32\drivers\etc\hosts "127.0.0.1    $hostHeader"

                Write-Host "done" -ForegroundColor Green                        
                        Write-Host ""
                Write-Host "Try to open http://$hostHeader"
            }
            else # Сайт уже существует, ничего не делаем
            {
                Write-Host "exist" -ForegroundColor Green
            }
        }       
    }
    finally
    {
        Set-Location $currentLocation
    }
}

Get-Task