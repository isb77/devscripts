# Удаляет все папки obj и bin

function Delete
{
    Param 
    (   
        [array] $folders 
    )

    if ($folders.Length -eq 0)
    {
        return
    }

    $folders | foreach {
        $folder = $_.FullName
        Write-Host "Remove $folder folder..." -NoNewline
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "done" -ForegroundColor Green
    }
    

}

$currentLocation = Get-Location

Write-Host "Finding folders..."

$filesBin = Get-ChildItem -Path $currentLocation -Recurse -Directory -Filter "bin" | Select-Object FullName #| Remove-Item -Recurse -Force
$filesObj = Get-ChildItem -Path $currentLocation -Recurse -Directory -Filter "obj" | Select-Object FullName #| Remove-Item -Recurse -Force


Delete($filesBin)
Delete($filesObj)
