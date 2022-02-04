
#figure out how to use the most common letter locations. ie look at all the possible words and choose one that has letters in the commonly found spots
#improved word scoring compared to original function. Does not count green letters towards the score anymore
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]  
    [string[]]$PossibleWords
)

$letterdict0 = @{}
$letterdict1 = @{}
$letterdict2 = @{}
$letterdict3 = @{}
$letterdict4 = @{}
$worddict = @{}

#build dictionary of letters/num times they occur
foreach ($word in $PossibleWords){
    $count = 0
    #write-verbose "Checking score of $word"
    foreach ($Letter in $word.ToCharArray()){
        #write-verbose $Letter
        if ($count -eq 0){
            if ($letterdict0.keys -contains $Letter){
                #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
                $letterdict0["$Letter"] = $letterdict0["$letter"] + 1
            }
            else{
                #write-verbose "Adding $Letter to the dictionary."
                $letterdict0["$Letter"] = 1
            }
        }
        if ($count -eq 1){
            if ($letterdict1.keys -contains $Letter){
                #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
                $letterdict1["$Letter"] = $letterdict1["$letter"] + 1
            }
            else{
                #write-verbose "Adding $Letter to the dictionary."
                $letterdict1["$Letter"] = 1
            }
        }
        if ($count -eq 2){
            if ($letterdict2.keys -contains $Letter){
                #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
                $letterdict2["$Letter"] = $letterdict2["$letter"] + 1
            }
            else{
                #write-verbose "Adding $Letter to the dictionary."
                $letterdict2["$Letter"] = 1
            }
        }
        if ($count -eq 3){
            if ($letterdict3.keys -contains $Letter){
                #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
                $letterdict3["$Letter"] = $letterdict3["$letter"] + 1
            }
            else{
                #write-verbose "Adding $Letter to the dictionary."
                $letterdict3["$Letter"] = 1
            }
        }
        if ($count -eq 4){
            if ($letterdict4.keys -contains $Letter){
                #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
                $letterdict4["$Letter"] = $letterdict4["$letter"] + 1
            }
            else{
                #write-verbose "Adding $Letter to the dictionary."
                $letterdict4["$Letter"] = 1
            }
        }
        $count += 1
    }
}

foreach ($letter in $letterdict0.keys){
    write-verbose "Position 0 : $letter : $($letterdict0[$letter])"
}
foreach ($letter in $letterdict1.keys){
    write-verbose "Position 1 : $letter : $($letterdict1[$letter])"
}
foreach ($letter in $letterdict2.keys){
    write-verbose "Position 2 : $letter : $($letterdict2[$letter])"
}
foreach ($letter in $letterdict3.keys){
    write-verbose "Position 3 : $letter : $($letterdict3[$letter])"
}
foreach ($letter in $letterdict4.keys){
    write-verbose "Position 4 : $letter : $($letterdict4[$letter])"
}

#write-verbose "Dictionary keys: $($letterdict.Keys)"
#write-verbose "Dictionary values: $($letterdict.Values)"
foreach ($word in $PossibleWords){
    $count = 0
    $score = 0
    foreach ($Letter in $word.ToCharArray()){
        if ($count -eq 0){
            $score += $letterdict0["$Letter"]
        }
        if ($count -eq 1){
            $score += $letterdict1["$Letter"]
        }
        if ($count -eq 2){
            $score += $letterdict2["$Letter"]
        }
        if ($count -eq 3){
            $score += $letterdict3["$Letter"]
        }
        if ($count -eq 4){
            $score += $letterdict4["$Letter"]
        }
        $count += 1
    }
    $worddict["$word"] = $score
}
#write-verbose "Word keys: $($worddict.keys)"
#write-verbose "Word values: $($worddict.values)"

$sortedByLetterPopularity = $worddict.GetEnumerator() | sort-object value -Descending | select-object -expandproperty key
$ofs = ", "
write-verbose "Best words according to letter popularity: "
foreach ($word in $sortedByLetterPopularity){
    write-verbose "$word : $($worddict[$word])"
}
if ($sortedByLetterPopularity.count -ne 1){ 

    $bestWordByLetterPopularity = $sortedByLetterPopularity[0]
    $lockedPositions = @()

    foreach ($num in 0..4){
        $LetterChanged = $False
        $firstLetter = ($bestWordByLetterPopularity)[$num]
        
        write-verbose "Letter to check to see if it is in every word in position $num : $firstLetter"

        foreach ($word in $sortedByLetterPopularity){
            if (-not($LetterChanged)){
                write-verbose "Word we are checking is $word. Character we are checking is $($word.ToCharArray()[$num]) in position $num"
                if ($word.ToCharArray()[$num] -ne $firstLetter){
                    write-verbose "The letter in position $num changed so it is not a locked position"
                    $LetterChanged = $TRUE
                }
            }
        }
        if (-Not($LetterChanged)){
            write-verbose "The letter in position $num never changed so $num is a locked position."
            $lockedPositions += $num
        }
    }
    write-verbose "Locked Positions: $lockedPositions"

    $wordsWithoutUnnecessaryDoubles = foreach ($word in $sortedByLetterPopularity){
        $allowedPositions = 0..4 | where-object {-Not($_ -in $lockedPositions)}
        $ofs = ""
        [string]$reducedWord = foreach ($num in $allowedPositions){
            $word[$num]
        }
        write-verbose "Word after removing locked positions: $reducedWord"

        $lettersOccurringMoreThanOnce = $reducedword.ToCharArray() | group-object | where-object {$_.count -gt 1}
        if (-not($lettersOccurringMoreThanOnce)){
            write-verbose "$word has no avoidable doubles so we are fine with it"
            write-output $word
        }
    }
    if ($wordsWithoutUnnecessaryDoubles){
        
            write-output $wordsWithoutUnnecessaryDoubles
            $ofs = ", "
            write-verbose "The words without unnecessary doubles in guess quality order are $wordsWithoutUnnecessaryDoubles."
        
    }
    else{
        write-output $sortedByLetterPopularity
        write-verbose "All words have unnecessary doubles so returning original list $sortedByLetterPopularity from letter popularity."
    }
}
else {
    write-verbose "The only word in the list is $sortedByLetterPopularity so it must be the word"
    write-output $sortedByLetterPopularity #only word so return it
}
