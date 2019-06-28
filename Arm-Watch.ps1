Param
(   
    [Parameter (Mandatory=$true, Position = 0)]
    [string] $taskName    
)


$targetFolder = $home + "\source\tasks\" 

Write-Host "Папка с задачами $targetFolder"

$ngWatch =
{   
    Invoke-Expression "ng build --watch"    
}

$path = [System.IO.Path]::combine($targetFolder, $taskName, "Loymax", "ARMv3")
Write-Host "Set Location $path"
Set-Location  $path

#$ngJob = Start-Job -ScriptBlock $ngWatch -Name "testjob"
#Wait-Job -Name "testjob"


$cmd = {
    param($a, $b)   
    Write-Host $a $b
    
    Invoke-Expression "ng build --watch"    
  }
  
  $foo = "foo"
  
  1..5 | ForEach-Object {
    Start-Job -ScriptBlock $cmd -ArgumentList $_, $foo
  }