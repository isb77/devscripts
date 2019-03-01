# добавить параметр вызова имя ветки
# создаватьт каталог с задачей. скачивать ветку

Param
(
    [Parameter (Mandatory=$true)]
    [string] $branchName
)

$targetFolder = "C:\Users\i.bondarenko\source\tasks"
$currentLocation = Get-Location
try
{

    $checkBranch = $(git ls-remote --exit-code --heads https://tfs.loymax.net/DefaultCollection/_git/Loymax $branchName) 
    $hasBranch = $checkBranch -like "*$branchName*"

    if(!$hasBranch) {
        Write-Host "Не найдена ветка $branchName" -ForegroundColor Red
        exit
    }
    
    $taskFolder = [System.IO.Path]::combine($targetFolder, $branchName)
    if((Test-Path $taskFolder)){
        Write-Host "Папка $branchName уже создана" -ForegroundColor Red
        exit
    }

    New-Item -ItemType directory -Path $taskFolder
    Set-Location $taskFolder

    git clone -b $branchName https://tfs.loymax.net/DefaultCollection/_git/Loymax    

    Write-Host "Location: " -NoNewLine
    Write-Host $currentLocation -ForegroundColor Green

    Set-Location Loymax
    $branch  = $(git rev-parse --abbrev-ref HEAD)
    Write-Host "branch: $branch"
    
    Set-Location ARMv2
    Write-Host "Build ARM..." -ForegroundColor Blue    
    yarn install
    gulp build --host "http://arm.$($branch).iis.local/api"
    Write-Host "done" -ForegroundColor Blue


    # Создаем сайт, если требуется
    $siteName = $branch
    if (!(Test-Path IIS:\Sites\$siteName))
    {        
        Write-Host "creating $branch.localhost web site ..." -ForegroundColor Yellow
        
        $physicalSitePath = [System.IO.Path]::combine($taskFolder, "Loymax\ARMv2\build")
        $physicalAppPath = [System.IO.Path]::combine($taskFolder, "Loymax\Kernel\Loymax.SystemApi")
        
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
finally
{
    Set-Location $currentLocation
}
