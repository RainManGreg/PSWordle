#combines the two scoring methods
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]  
    [string]$WordlePath,
    [Parameter(Mandatory=$True)]  
    [string]$AlgorithmDirectory,
    [Parameter(Mandatory=$True)]  
    [string[]]$WordsToTest,
    [string]$FirstWord = "ALERT",
    [switch]$ObjOutput
)

$algorithms = get-childitem $AlgorithmDirectory
foreach ($word in $WordsToTest){
    foreach ($algorithm in $algorithms){
        write-verbose $algorithm.fullname
        $name = $algorithm.Name
        $results = & "$WordlePath" -WordToGuess $word -Cheat -Simulation -FirstWord $FirstWord -AlgorithmFile "$($algorithm.fullname)"
        $prop = [ordered]@{
            "Algorithm" = $name
            "WordToGuess" = $Word
            "FirstWord" = $FirstWord
            "Score" = $results.score
            "GuessedWords" = "$($results.GuessedWords)"
        }
        if ($objOutput){
            $prop = [ordered]@{
                "Algorithm" = $name
                "WordToGuess" = $Word
                "FirstWord" = $FirstWord
                "Score" = $results.score
                "GuessedWords" = $results.GuessedWords
            } 
        }

        new-object -TypeName psobject -prop $prop
    }
}
