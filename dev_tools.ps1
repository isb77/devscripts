Param (

    [Parameter (Mandatory=$true, Position = 0)]
    [string] $version = 0

)
function Build-SDK {
    nuget pack -Version "2019.1.0.$version-local" -Properties Configuration=Debug -IncludeReferencedProjects -symbols
}

Build-SDK