Param
(    
    [Parameter (Mandatory=$false, Position = 0)]
    [string] $pluginName = "Loymax.Wallet",

    [Parameter (Mandatory=$false, Position = 1)]
    [string] $dbName = "master_Loymax",

    [Parameter (Position = 2)]
    [string] $sqlserver = "(localdb)\MSSQLLocalDB"    
)

function Database_ExecuteScripts([string] $filePath, [guid] $newDeploysGuid)
{
    try
    {
        $filename = [io.path]::GetFileNameWithoutExtension($filePath)
        Write-Host "`t$filename..." -NoNewline

        $check = IsExecuted $filename;

        # Выполняем первоначальное создание (инициализацию) БД.
        if ($check -eq $true)
        {
            Write-Host "Skipped" -ForegroundColor DarkYellow
            return
        }

	    $sw = [Diagnostics.Stopwatch]::StartNew()
        
        # Выполняем
        #Invoke-SqlCmd -ServerInstance $sqlserver -InputFile $filePath -Database $dbName
        
        $sw.Stop()
	    $elapsed = [convert]::ToInt32($sw.Elapsed.TotalMilliseconds)
	
        Write-Host "Done {$elapsed ms} ..." -NoNewline -ForegroundColor Green
		$dateTimeNow = [DateTime]::Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fff')
		
		$insertScript = "INSERT INTO [Config_Script] ([ID], [Description], [ExecutionDate], [ConfigDeployId], [Duration]) VALUES('$($filename)','','$dateTimeNow', '$newDeploysGuid', $elapsed )"
		# Сохраняем дату выполнения скрипта
        #Invoke-Sqlcmd -ServerInstance $sqlserver -Database $dbName -Query $insertScript
        Write-Host "Inserted" -ForegroundColor Green
    }
    catch
    {
	$_.Exception | format-list -force | Out-String|% {Write-Error $_}
        throw
    }
}

function IsExecuted([string] $filename)
{
    $countScript = "SELECT count(*) Count FROM [Config_Script] WHERE [ID] ='$($filename)'"
    # Проверяем, выполнялся ли скрипт обновления
        
    $res = Invoke-Sqlcmd -ServerInstance $sqlserver -Database $dbName -Query $countScript | % {$_['Count']}
    if ($res.Count -eq 1)    
    {    
        return $TRUE;
    }

    return $FALSE;
}

$currentLocation = Get-Location
$ns = @{ defaultNamespace = "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd" }
$deployGuid = [guid]::newguid()

clear
Write-Host 'Working folder: ' $currentLocation

$files = Get-ChildItem -Path $currentLocation -Recurse -Filter *.nuspec | Select-Xml -XPath "//defaultNamespace:id[. = ""$pluginName""]" -Namespace $ns | Group path | Select Name
$scripts = $files | foreach {
    $directory = [System.IO.Path]::GetDirectoryName($_.Name);
    $directory
    $sqlPaths = Select-Xml -Path $_.Name -XPath "//defaultNamespace:file/@src" -Namespace $ns | Select-Object -ExpandProperty Node | Where {$_.value -match "sql$"} 

    $sqlPaths | foreach {
        $dbPath = [System.IO.Path]::combine($directory, $_.value)
        Get-ChildItem $dbPath -Recurse | foreach {$_.FullName}
    }
} 

Import-Module "sqlps" -DisableNameChecking
$scripts | where {$_ -match "sql$"} | % {        
    Database_ExecuteScripts -db $database -filePath $_ -newDeploysGuid $deployGuid
}
