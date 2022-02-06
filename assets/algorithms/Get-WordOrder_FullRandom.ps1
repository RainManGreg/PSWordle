
#improved word scoring compared to original function. Does not count green letters towards the score anymore
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]  
    [string[]]$PossibleWords,
    [psobject[]]$WordsArray
)

$PossibleWords | get-random