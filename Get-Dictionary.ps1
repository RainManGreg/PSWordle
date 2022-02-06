[CmdletBinding()]
param(
    [switch]$HardMode
)
<#
.DESCRIPTION
Retrieves a dictionary of 5 letter words.

.OUTPUTS
An array of all 5 letter words in the dictionary
#>

if ($HardMode){
    $filename = "hardmode.txt"
    $url = "https://raw.githubusercontent.com/RainManGreg/PSWordle/main/assets/dicts/hardmode.txt"
}    
else{
    $filename = "dict.txt"
    $url = "https://raw.githubusercontent.com/RainManGreg/PSWordle/main/assets/dicts/dict.txt"
}
if ($PSScriptRoot){
    $dictpath = join-path -Path $PSScriptRoot -ChildPath "assets" | join-path -ChildPath "dicts" | join-path -ChildPath $filename 
}
else {
    $dictpath = ".\$filename"
}
if (test-path $dictpath){
    $lower = get-content $dictpath -Encoding ascii | where-object {$_ -ne ""}
    $lower | foreach-object {$_.toupper()}

}
else {
    $tempdict = (join-path -path $env:temp -ChildPath $filename)
    if (-not(test-path $tempdict)){
        (invoke-webrequest -URI $url).content | out-file $tempdict -Encoding ascii
    }
    $lower = get-content $tempdict -Encoding ascii | where-object {$_ -ne ""}
    $lower | foreach-object {$_.toupper()}
}
