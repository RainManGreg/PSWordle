[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]  
        [string[]]$PossibleWords,
        [Parameter(Mandatory=$True)]  
        [PSObject[]]$WordsArray
    )


function Get-GuessHelpRegex {
<# Attributes of the custom objects are:
    "Letter" : the letter that was guessed
    "Position" : the position of the letter in the word (0-5)
    "FoundExact" : $True if the letter and position match the word to guess. $False otherwise.
    "FoundContains" : $True if the letter is in the word to guess but the position is incorrect. $False otherwise
#>
    [CmdletBinding()]
    Param (
        [PSCustomObject[]]$WordsArray
    )
    $pos0excluded = @()
    $pos1excluded = @()
    $pos2excluded = @()
    $pos3excluded = @()
    $pos4excluded = @()

    $singleletters = @()
    $doubledletters = @()
    $tripledletters = @()
    $quadrupledletters = @()

    $pos0 = $pos1 = $pos2 = $pos3 = $pos4 = $Null

    foreach ($word in $wordsarray){
        $ofs = ""
        write-verbose "Word to check: $($word.letter)"
        $lettersFoundThisRound = @()
        $lettersFoundThisRoundExact = @()
        if (-not($pos0)){
            if ($word[0].FoundExact){
                $pos0 = [char]$word[0].Letter
                $lettersFoundThisRoundExact += $pos0
            }
            else{
                if ($word[0].FoundContains){
                    #letter is in the word but not this position. exclude it for the future and ensure it is in the next guess
                    write-verbose "$($word[0].Letter) in the word but not in position 0. Excluding for next time."
                    $lettersFoundThisRound += [char]$word[0].Letter
                    $pos0excluded += [char]$word[0].Letter
                } 
                else {
                    #letter isn't anywhere in the word, add to all excluded lists
                    write-verbose "$($word[0].Letter) is not in the word. Excluding it everywhere."
                    $pos0excluded += [char]$word[0].Letter
                    $pos1excluded += [char]$word[0].Letter
                    $pos2excluded += [char]$word[0].Letter
                    $pos3excluded += [char]$word[0].Letter
                    $pos4excluded += [char]$word[0].Letter
                }
            }
        }
        else{
            $lettersFoundThisRoundExact += $pos0
        }
        if (-not($pos1)){
            if ($word[1].FoundExact){
                $pos1 = [char]$word[1].Letter
                $lettersFoundThisRoundExact += $pos1
            }
            else{
                if ($word[1].FoundContains){
                    #letter is in the word but not this position. exclude it for the future and ensure it is in the next guess
                    write-verbose "$($word[1].Letter) in the word but not in position 1. Excluding for next time."
                    $pos1excluded += [char]$word[1].Letter
                    $lettersFoundThisRound += [char]$word[1].Letter
                } 
                else {
                    #letter isn't anywhere in the word, add to all excluded lists
                    if (-not([char]$word[1].Letter -in $lettersFoundThisRound)){
                        write-verbose "$($word[1].Letter) is not in the word and not already yellow this round. Excluding it everywhere."
                        $pos0excluded += [char]$word[1].Letter
                        $pos1excluded += [char]$word[1].Letter
                        $pos2excluded += [char]$word[1].Letter
                        $pos3excluded += [char]$word[1].Letter
                        $pos4excluded += [char]$word[1].Letter
                    }
                }
            }
        }
        else{
            $lettersFoundThisRoundExact += $pos1
        }
        if (-not($pos2)){
            if ($word[2].FoundExact){
                $pos2 = [char]$word[2].Letter
                $lettersFoundThisRoundExact += $pos2
            }
            else{
                if ($word[2].FoundContains){
                    #letter is in the word but not this position. exclude it for the future and ensure it is in the next guess
                    write-verbose "$($word[2].Letter) in the word but not in position 2. Excluding for next time."
                    $lettersFoundThisRound += [char]$word[2].Letter
                    $pos2excluded += [char]$word[2].Letter
                } 
                else {
                    #letter isn't anywhere in the word, add to all excluded lists
                    if (-not([char]$word[2].Letter -in $lettersFoundThisRound)){
                        write-verbose "$($word[2].Letter) is not in the word and not already yellow this round. Excluding it everywhere."
                        $pos0excluded += [char]$word[2].Letter
                        $pos1excluded += [char]$word[2].Letter
                        $pos2excluded += [char]$word[2].Letter
                        $pos3excluded += [char]$word[2].Letter
                        $pos4excluded += [char]$word[2].Letter
                    }
                }
            }
        }
        else{
            $lettersFoundThisRoundExact += $pos2
        }
        if (-not($pos3)){
            if ($word[3].FoundExact){
                $pos3 = [char]$word[3].Letter
                $lettersFoundThisRoundExact += $pos3
            }
            else{
                if ($word[3].FoundContains){
                    #letter is in the word but not this position. exclude it for the future and ensure it is in the next guess
                    write-verbose "$($word[3].Letter) in the word but not in position 3. Excluding for next time."
                    $lettersFoundThisRound += [char]$word[3].Letter
                    $pos3excluded += [char]$word[3].Letter
                } 
                else {
                    #letter isn't anywhere in the word, add to all excluded lists
                    if (-not([char]$word[3].Letter -in $lettersFoundThisRound)){
                        write-verbose "$($word[3].Letter) is not in the word and not already yellow this round. Excluding it everywhere."
                        $pos0excluded += [char]$word[3].Letter
                        $pos1excluded += [char]$word[3].Letter
                        $pos2excluded += [char]$word[3].Letter
                        $pos3excluded += [char]$word[3].Letter
                        $pos4excluded += [char]$word[3].Letter
                    }
                }
            }
        }
        else{
            $lettersFoundThisRoundExact += $pos3
        }
        if (-not($pos4)){
            if ($word[4].FoundExact){
                $pos4 = [char]$word[4].Letter
                $lettersFoundThisRoundExact += $pos4
            }
            else{
                if ($word[4].FoundContains){
                    #letter is in the word but not this position. exclude it for the future and ensure it is in the next guess
                    write-verbose "$($word[4].Letter) in the word but not in position 4. Excluding for next time."
                    $lettersFoundThisRound += [char]$word[4].Letter
                    $pos4excluded += [char]$word[4].Letter
                } 
                else {
                    #letter isn't anywhere in the word, add to all excluded lists
                    if (-not([char]$word[4].Letter -in $lettersFoundThisRound)){
                        write-verbose "$($word[4].Letter) is not in the word and not already yellow this round. Excluding it everywhere."
                        write-verbose "$($word[4].Letter) is not in the word. Excluding it everywhere."
                        $pos0excluded += [char]$word[4].Letter
                        $pos1excluded += [char]$word[4].Letter
                        $pos2excluded += [char]$word[4].Letter
                        $pos3excluded += [char]$word[4].Letter
                        $pos4excluded += [char]$word[4].Letter
                    }
                }
            }
        }
        else{
            $lettersFoundThisRoundExact += $pos4
        }
        $ofs = ""
        $currentWord = "$($word.letter)"
        $lastWord = "$($WordsArray[-1].letter)"
        write-verbose "$currentWord is current word. $lastword is last word"
        if ($currentword -eq $lastword){ #only run on last word
            write-verbose "Words equal each other"
            write-verbose "Found letters: $lettersFoundThisRound"
            $groupedFoundLetters = $lettersFoundThisRound | Group-Object

            #add the exact matches of a letter to the yellow matches of a letter

            $groupedFoundLettersExact = $lettersFoundThisRoundExact | Group-Object
            write-verbose "Grouped found letters exact: $($groupedFoundLettersExact.name)"
            #write-output $groupedFoundLetters
            foreach ($letter in $groupedFoundLetters){
                $FoundLettersCount = $groupedFoundLettersExact | where-object {$_.name -eq $Letter.name} | select-object -ExpandProperty count
                $count = $letter.count + $FoundLettersCount
                Write-verbose "Letter counts for regex purposes: $($letter.name) : Yellows count [$($letter.count)] : Greens count [$FoundLettersCount]"
                if ($count -eq 4){
                    $quadrupledletters += $letter.name
                }
                elseif ($count -eq 3){
                    $tripledletters += $letter.name
                }
                elseif ($count -eq 2){
                    $doubledletters += $letter.name
                }
                else{
                    $singleletters += $letter.name
                }
            }
            write-verbose "Single letters: $singleletters"
            write-verbose "Double letters: $doubledletters"
            write-verbose "Triple letters: $tripledletters"
            write-verbose "Quadruple letters: $quadrupledletters"
        }   
    }

    if ($pos0){
        $pos0regex = $pos0
    }
    else {
        $pos0regex = '[^'
        $uniqueLetters = $pos0excluded | sort-object | get-unique
        $ofs = "" #weird $ofs variable makes array written to string have no separator because value is empty string
        $lettersToAdd = "$uniqueLetters"
        $pos0regex += "$lettersToAdd]"
    }
    write-verbose "regex pos 0 string is $pos0regex"
    if ($pos1){
        $pos1regex = $pos1
    }
    else {
        $pos1regex = '[^'
        $uniqueLetters = $pos1excluded | sort-object | get-unique
        $ofs = "" #weird $ofs variable makes array written to string have no separator because value is empty string
        $lettersToAdd = "$uniqueLetters"
        $pos1regex += "$lettersToAdd]"
    }
    write-verbose "regex pos 1 string is $pos1regex"
    if ($pos2){
        $pos2regex = $pos2
    }
    else {
        $pos2regex = '[^'
        $uniqueLetters = $pos2excluded | sort-object | get-unique
        $ofs = "" #weird $ofs variable makes array written to string have no separator because value is empty string
        $lettersToAdd = "$uniqueLetters"
        $pos2regex += "$lettersToAdd]"
    }
    write-verbose "regex pos 2 string is $pos2regex"
    if ($pos3){
        $pos3regex = $pos3
    }
    else {
        $pos3regex = '[^'
        $uniqueLetters = $pos3excluded | sort-object | get-unique
        $ofs = "" #weird $ofs variable makes array written to string have no separator because value is empty string
        $lettersToAdd = "$uniqueLetters"
        $pos3regex += "$lettersToAdd]"
    }
    write-verbose "regex pos 3 string is $pos3regex"
    if ($pos4){
        $pos4regex = $pos4
    }
    else {
        $pos4regex = '[^'
        $uniqueLetters = $pos4excluded | sort-object | get-unique
        $ofs = "" #weird $ofs variable makes array written to string have no separator because value is empty string
        $lettersToAdd = "$uniqueLetters"
        $pos4regex += "$lettersToAdd]"
    }
    write-verbose "regex pos 4 string is $pos4regex"

    $regex = $pos0regex + $pos1regex + $pos2regex + $pos3regex + $pos4regex 
    
    #add forward lookahead assertions
    if (-not($singleletters) -and -not($doubledletters) -and -not($tripledletters) -and -not($quadrupledletters)){
        write-verbose "No yellow letters found. Final regex is: $regex"
    }
    else{
        write-verbose "Forward Lookaheads needed. Starting regex is: $regex"
        $additionalRegex = "(?=$regex)"
        if ($SingleLetters){
            foreach ($Letter in $singleletters){
                $additionalRegex += "(?=.*$letter.*)"
            }
            write-verbose "Regex after adding single letters: $additionalregex"
        }
        if ($doubledletters){
            foreach ($Letter in $doubledletters){
                $additionalRegex += "(?=.*$letter.*$letter.*)"
            }
            write-verbose "Regex after adding double letters: $additionalregex"
        }
        if ($tripledletters){
            foreach ($Letter in $tripledletters){
                $additionalRegex += "(?=.*$letter.*$letter.*$letter.*)"
            }
            write-verbose "Regex after adding triple letters: $additionalregex"
        }
        if ($quadrupledletters){
            foreach ($Letter in $quadrupledletters){
                $additionalRegex += "(?=.*$letter.*$letter.*$letter.*$letter.*)"
            }
            write-verbose "Regex after adding quadruple letters: $additionalregex"
        }
        $regex = $additionalRegex
        write-verbose "Final regex after adding forward lookaheads: $regex"
    }
    $regex
}

function Get-GuessHelpPossibleWords {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]  
        [string]$Regex,
        [string[]]$Dictionary
    )

    if (-not($psboundparameters.ContainsKey($Dictionary))){
        $Dictionary = Get-Dictionary 
    }
    $PossibleWords = $Dictionary | select-string -Pattern $Regex
    $ofs = " "
    write-verbose "Possible words: $PossibleWords"
    $PossibleWords
}

function Get-WordOrder_Lookahead {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]  
        [string[]]$PossibleWords,
        [Parameter(Mandatory=$True)]  
        [PSObject[]]$WordsArray,
        [ValidateSet("Mean","NoFailures")]
        [string]$OptimizeFor
    )
    $DictOfTotalScores = @{}#dictionary that will hold scores of words
    $DictOfWorstScores = @{}
    $i = 0
    foreach ($guess in $PossibleWords){
        $wordsToTestAgainst = $PossibleWords | where-object {$_ -ne $guess}
        write-verbose "$guess : $($wordstotestagainst.count)"
        $runningScore = 0 #
        $worstScore = 0
        Write-Progress -Activity "Simulating Round $($WordsArray.count + 1) : Guess [$i / $($wordsToTestAgainst.count)] $Guess" -PercentComplete (($i/$wordsToTestAgainst.count)*100)
        $i += 1
        foreach ($Answer in $wordsToTestAgainst){
            $result = Test-Guess -Guess $guess -Word $Answer
            $resultsArray = $WordsArray + @(,$result) #keep track of all the guesses in an array of arrays
            if (-not((($result | select-object -uniq FoundExact).FoundExact.count -eq 1) -and (($result | select-object -uniq FoundExact).FoundExact[0]))){ #ie you didn't win the game
                $possiblewordsInner = $NULL
                $regex = Get-GuessHelpRegex -WordsArray $resultsArray 
                $possiblewordsInner = Get-GuessHelpPossibleWords -Regex $regex -Dictionary $PossibleWords
                $runningScore += $possiblewordsInner.count
                if ($possiblewordsInner.count -gt $worstScore){
                    $worstScore = $possiblewordsInner.count
                }
                write-verbose "Guess [$guess] for word [$Answer] : $($possiblewordsInner.count)"
            }
            else{
                write-verbose "Guess [$guess] for word [$Answer] was correct: 0"
            }
        }
        write-verbose "[$guess] total score : $runningScore"
        write-verbose "[$guess] worst score : $worstScore"
        $DictOfTotalScores[$guess] = $runningScore
        $DictOfWorstScores[$guess] = $worstScore
    }
    $sortedTotal = $DictOfTotalScores.GetEnumerator() | sort-object value | select-object -expandproperty key
    write-verbose "Sorted Guesses by total:"
    foreach ($word in $sortedTotal){
        write-verbose "$word : $($DictOfTotalScores[$word])"
    }
    $sortedWorst = $DictOfWorstScores.GetEnumerator() | sort-object value | select-object -expandproperty key
    write-verbose "Sorted Guesses by total:"
    foreach ($word in $sortedWorst){
        write-verbose "$word : $($DictOfWorstScores[$word])"
    }
    if ($OptimizeFor -eq "NoFailures"){
        write-verbose "Returning the list optimized against failures"
        $sortedWorst
    }
    else{
        write-verbose "Returning the list optimized for lowest mean"
        $sortedTotal
    }   
}

Get-WordOrder_Lookahead -PossibleWords $possiblewords -WordsArray $resultsArray -OptimizeFor NoFailures
