Param
(    
    [Parameter (Mandatory=$true, Position = 0)]
    [string] $pluginName = "Loymax.Plugins.PrivateClubs",

    [Parameter (Mandatory=$true, Position = 1)]
    [string] $dbName = "master_Loymax",

    [Parameter (Position = 2)]
    [string] $sqlserver = "(localdb)\MSSQLLocalDB"    
)

function Deploy_Create([string] $version)
{
	try
	{
		$databaseServerConfig.Database.Name | Where-Object { if($_ -match "_Loymax$") { $dbLoymax = $server.Databases[$_] } }
		$authorDeploy = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
		$dateTimeNow = [DateTime]::Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fff')
					
		# Создать новый деплой
		$newDeploysGuid = New-Guid
        $createNewDeploy = "INSERT INTO [Config_Deploy] ([PackageVersion], [Date], [IsSuccess], [Author], [ExternalId]) VALUES('$version', '$dateTimeNow', '0', '$authorDeploy', CAST('$newDeploysGuid' AS UNIQUEIDENTIFIER))"
        Invoke-SqlCmd -ServerInstance $sqlserver -Query $createNewDeploy -Database $dbName		             
	}
	catch
	{
		$_.Exception | format-list -force | Out-String|% {Write-Error $_}
        	throw
	}       
	                               
	return $newDeploysGuid
}


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
        Invoke-SqlCmd -ServerInstance $sqlserver -InputFile $filePath -Database $dbName
        
        $sw.Stop()
	    $elapsed = [convert]::ToInt32($sw.Elapsed.TotalMilliseconds)
	
        Write-Host "Done {$elapsed ms} ..." -NoNewline -ForegroundColor Green
		$dateTimeNow = [DateTime]::Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fff')
		
		$insertScript = "INSERT INTO [Config_Script] ([ID], [Description], [ExecutionDate], [ConfigDeployId], [Duration]) VALUES('$($filename)','','$dateTimeNow', '$newDeploysGuid', $elapsed )"
		# Сохраняем дату выполнения скрипта
        Invoke-Sqlcmd -ServerInstance $sqlserver -Database $dbName -Query $insertScript
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
    
    #Write-Host $countScript
    $res = Invoke-Sqlcmd -ServerInstance $sqlserver -Database $dbName -Query $countScript | % {$_['Count']}
    
    if ($res -eq 1)    
    {    
        return $TRUE;
    }

    return $FALSE;
}

$currentLocation = Get-Location
$ns = @{ defaultNamespace = "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd" }

Clear-Host
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
$deployGuid = Deploy_Create -version "Local deploy $pluginName"
$scripts | where {$_ -match "sql$"} | % {        
    Database_ExecuteScripts -db $database -filePath $_ -newDeploysGuid $deployGuid
}
