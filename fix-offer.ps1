# Simulation of Get-Content
$content = Get-Content C:\Users\i.bondarenko\source\tasks\master\offer_import.xml -Encoding utf8

$i = 0
$result = $content.ForEach({
    if($_ -match '(Chain Order=")(\d+)(")'){
      $i++
      $r = '$1 ' + $i + ' $3'
        #Write-Host $r
        $_ -replace '(Chain Order=")(\d+)(")', $r
    } else {
    $_
    }
    
    
})

$result | Out-File -FilePath "C:\Users\i.bondarenko\source\tasks\master\offer_import2.xml" -Encoding utf8 -NoClobber
