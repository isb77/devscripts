Param (

    [Parameter (Mandatory=$true, Position = 0)]
    [string] $version = 0

)

nuget pack -Version "2020.2.0.$version-local" -Properties Configuration=Debug -IncludeReferencedProjects -symbols