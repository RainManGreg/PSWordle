
#improved word scoring compared to original function. Does not count green letters towards the score anymore
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]  
    [string[]]$PossibleWords
)

$letterdict = @{}
$worddict = @{}

$lockedPositions = @()

foreach ($num in 0..4){
    $LetterChanged = $False
    $firstLetter = $PossibleWords[0].ToCharArray()[$num]
    
    write-verbose "Letter to check to see if it is in every word in position $num : $firstLetter"

    foreach ($word in $PossibleWords){
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

#build dictionary of letters/num times they occur
foreach ($word in $PossibleWords){
    $allowedPositions = 0..4 | where-object {-Not($_ -in $lockedPositions)}
    $ofs = ""
    [string]$reducedWord = foreach ($num in $allowedPositions){
        $word[$num]
    }
    write-verbose "Word after removing locked positions: $reducedWord"
    foreach ($Letter in $reducedword.ToCharArray()){
        #write-verbose $Letter
        if ($letterdict.keys -contains $Letter){
            #write-verbose "$Letter is already in the dictionary. Incrementing the count by one."
            $letterdict["$Letter"] = $letterdict["$letter"] + 1
        }
        else{
            #write-verbose "Adding $Letter to the dictionary."
            $letterdict["$Letter"] = 1
        }
    }
}


write-verbose "Dictionary keys: $($letterdict.Keys)"
write-verbose "Dictionary values: $($letterdict.Values)"
foreach ($word in $PossibleWords){
    $allowedPositions = 0..4 | where-object {-Not($_ -in $lockedPositions)}
    $ofs = ""
    [string]$reducedWord = foreach ($num in $allowedPositions){
        $word[$num]
    }
    write-verbose "Word after removing locked positions: $reducedWord"
    $score = 0
    foreach ($Letter in $reducedword.ToCharArray()){
        $score += $letterdict["$Letter"]
    }
    $worddict["$word"] = $score
}

foreach ($letter in $letterdict.keys){
    write-verbose "$letter : $($letterdict[$letter])"
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
