$remoteBranches = git branch -r | ForEach-Object { $newName = $_.Replace(' ','').Replace('*','') ; $_ ="$newName"; $_} #| Where {$_ -like '*origin*'}
$localBranches = git branch | ForEach-Object { $newName = $_.Replace(' ','').Replace('*',''); $_ ="origin/$newName"; $_} 

$localBranches | ForEach-Object{
    
    $localBranch = $_
    $found = $remoteBranches | Where { $_ -eq "$localBranch"}

    if ($found.Length -eq 0)
    {
        #Write-Host ('{0,20}{1}' -f $_,' local only ') -ForegroundColor Green     
        $_ = [PSCustomObject]@{Branch = $localBranch; Remote = ''}
    }
    else
    {
        #Write-Host ('{0,30}{1}' -f $_,' remote ') -ForegroundColor Red
        $_ = [PSCustomObject]@{Branch = $localBranch; Remote = '  *'}
    }

    $_;
} | Write-Output



