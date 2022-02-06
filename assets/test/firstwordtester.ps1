[CmdletBinding()]
    param(
        [string]$FilePath = "C:\temp\wordleresults\wordle.txt",
        [ValidateSet("Original","NoPointsForLockedLetters", "PositionScoring", "ComboScoring", "ComboScoringOptimized")]
        [string]$Algorithm = "Original",
        [string]$StartingWord
    )

function Get-Dictionary {
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
}

$alg = join-path ".." -ChildPath "algorithms" | join-path -ChildPath "Get-WordOrder_ComboScoringOptimized.ps1"

$dict = Get-Dictionary
#dictreduced = $dict | select -first 10
$wordorder = & "$alg" -PossibleWords $dict
$FOUND = $false
$count = 0
if($PSBoundParameters.ContainsKey($StartingWord)){
    do{
        if ($wordorder[$count] -eq $StartingWord){ 
            $FOUND = $TRUE
            $wordorder[$count]
        }
        else { 
            $count += 1 
        }
    }while (-not($FOUND -eq $TRUE))
}

$wordorder = $wordorder | select-object -Last ($wordorder.count - $count)
$path = "..\..\start-wordle-alginput.ps1"
write-output $path
foreach ($firstword in $wordorder){
    $j = 0
    $i += 1
    write-progress -activity "Simulating wordle ... [$i/$($wordorder.count)] Full runs : checking first word [$firstword]" -PercentComplete (($i / $wordorder.count)*100)
    $allwordsoutput = foreach ($wordtoguess in $dict){
        $j += 1
        write-progress -Activity "Simulating wordle ... [$j/$($dict.count)] Word to Guess : [$wordtoguess]    [[$i/$($wordorder.count)]] First Word : [$firstword] " -PercentComplete (($i / $wordorder.count)*100)
        & "$path" -WordToGuess $wordtoguess -Cheat -Simulation -FirstWord $firstword -allowedrounds 100 -AlgorithmFile $alg
    }
    $mean = $allwordsoutput | select-object -expandproperty score | measure-object -Average | select-object count, average
    $failedwordsequences = $allwordsoutput | where-object {$_.score -gt 6} | select-object GuessedWords
    $failedwords = foreach ($seq in $failedwordsequences){
        write-output $seq.guessedwords[-1]
    }
    $firstguess = $allwordsoutput[0].GuessedWords[0]
    $prop = @{
        'Guess' = $firstguess;
        'Mean' = $mean.average;
        'FailedCount' = $dict.count - $mean.count;
        'FailedWords' = "$failedwords"
    }
    $obj = new-object -typename psobject -prop $prop
    "$($obj.Guess), $($obj.Mean), $($obj.FailedCount), $($obj.failedwords)" | out-file -Append -FilePath $FilePath
    write-output $obj
}


