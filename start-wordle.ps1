[CmdletBinding()]
    param(
        [int]$ALLOWEDROUNDS = 6
    )

function Get-Dictionary {
    (invoke-webrequest -URI https://raw.githubusercontent.com/charlesreid1/five-letter-words/master/sgb-words.txt).content.split("`n") | where-object {$_ -ne ""}
}

function Get-WordToGuess {
	[CmdletBinding()]
    param(
        [int] $Seed
	)

    $Dictionary = Get-Dictionary
    if ($PSBoundParameters.ContainsKey('Seed')){
        
        $ResultWord = $Dictionary | get-random -SetSeed $Seed
    }
    else {
        $ResultWord = $Dictionary | get-random 
    }
    write-verbose "Word to guess is [$ResultWord]"
    $ResultWord
}

function Test-GuessIsWord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Guess
    )
    $inDictionary = $guess -in (Get-Dictionary)
    write-verbose "Guess is in dictionary: $inDictionary"
    $inDictionary
}

function Test-GuessLength {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Guess
    )
    write-verbose "Length of guess is [$($Guess.length)]"
    $Guess.length -eq 5
}

function Get-Guess {
    [CmdletBinding()]
    param()
    do{
        $guess = $NULL
        $guess = Read-Host "`nPlease enter your 5 letter guess: "
        if (-Not(Test-GuessLength -Guess $guess)){
            write-host "Invalid word length. Word must be 5 letters."
        }
        elseif (-Not(Test-GuessIsWord -Guess $guess)){
            write-host "Invalid word. Please enter a valid word."
        }
        
    } until (((Test-GuessIsWord -Guess $guess) -eq $True) -and ((Test-GuessLength -Guess $guess) -eq $True))
    $guess = $guess.toupper()
    write-verbose "Guessed word is [$guess]"
    $guess
}

function Get-Seed {
    [CmdletBinding()]
    param ()
    do{ 
        try{
            [int]$seed = Read-Host "Enter an integer seed" -ErrorAction SilentlyContinue
            $ValidSeed = $True
        }
        catch {
            Write-host "Invalid input. Please enter an integer"
            $ValidSeed = $False
        }
    } until ($ValidSeed)
    write-verbose "Seed is [$seed]"
    $seed
}

function Get-GameType {
    [CmdletBinding()]
    param()
    do{ 
        try{
            [int]$UserInput = Read-Host "Enter a game type. '1' for random word or '2' for seeded game (perhaps to play the same game as a friend)" -ErrorAction SilentlyContinue
            if ($UserInput -eq 1){
                $GameType = "random"
            }
            elseif ($UserInput -eq 2){
                $GameType = "seed"
            }
            else{
                write-host "Invalid input. Please enter '1' or '2'"
            }
            
        }
        catch {
            write-host "Invalid input. Please enter '1' or '2'"
        }
    } until (($GameType -eq "random") -or ($GameType -eq "seed"))
    write-verbose "Game type is [$GameType]"
    write-output $GameType
}

function Test-CorrectPlacement {
    #returns true if letter is in the correct position in the word, or if letter is in the word and the 'contains' switch is used
    param(
        [Parameter(Mandatory=$True)]
        [char]$Letter,
        [Parameter(Mandatory=$True)]
        [int]$Position,
        [Parameter(Mandatory=$True)]
        [PSCustomObject]$Word,
        [switch]$Contains
    )
    if ($Contains){
        $letter -in $Word.Letter
    }
    else { 
        $LetterToCheck = $Word | where-object {$_.Position -eq $Position}
        $LetterToCheck.Letter -eq $Letter
    }
}

function New-LetterObjectArray {
    param(
        [Parameter(Mandatory=$True)]
        [string]$Word
    )
    $LetterPosition = 0
    foreach ($Letter in $Word.ToCharArray()){
        $properties = @{
            'Letter' = $Letter;
			'Position' = $LetterPosition;
		}
		New-Object -TypeName PSObject -Prop $properties
        $LetterPosition += 1
    }
}

function Write-VerboseResults {
    [CmdletBinding()]
    Param (
        [PSCustomObject]$Word
    )
    if ("FoundExact" -in ($Word | get-member | select-object -expandproperty name)){ #handle different array types
        foreach ($letter in $Word){
            write-verbose "[$($letter.letter)] in position [$($letter.position)]. FoundExact = $($letter.FoundExact) and FoundContains = $($letter.FoundContains)"
        }
    }
    else{
        foreach ($letter in $Word){ #handle different array types
            write-verbose "[$($letter.letter)] in position [$($letter.position)]"
        }
    }
}
function Test-Guess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Guess,
        [Parameter(Mandatory=$True)]
        [string]$Word
    )
    
    $GuessObjectArray = New-LetterObjectArray -Word $Guess
    $WordObjectArray = New-LetterObjectArray -word $Word
    $ResultObjectArray = @()

    #Start with exact matches
    foreach ($letter in $GuessObjectArray){
        if (Test-CorrectPlacement -Letter $letter.Letter -Position $letter.Position -Word $WordObjectArray){
            #add found letter to result object array
            $properties = @{
                'Letter' = $letter.Letter;
                'Position' = $letter.Position;
                'FoundExact' = $True;
                'FoundContains' = $False;
            }
            Write-Verbose "Exact match on [$($letter.letter)] in position [$($letter.position)]"
            $ResultObjectArray += New-Object -TypeName PSObject -Prop $properties
            
            #remove letter from word object array (since it is already found you don't want to find it again)
            Write-Verbose "Removing [$($letter.letter)] in position [$($letter.position)] from word object array"
            $ObjToRemove = $WordObjectArray | where-object {$_.Position -eq $letter.Position}
            $WordObjectArray = $WordObjectArray | Where-Object {$_ -ne $ObjToRemove}

            #remove letter from guess object array (since it is already found you don't want to guess it again)
            Write-Verbose "Removing [$($letter.letter)] in position [$($letter.position)] from guess object array"
            $ObjToRemove = $GuessObjectArray | where-object {$_.Position -eq $letter.Position}
            $GuessObjectArray = $GuessObjectArray | Where-Object {$_ -ne $ObjToRemove}
        }
    }

    function Write-GameInstructions {
        clear-host
        Write-host "Welcome to Wordle!"
        Write-host "Guess the five letter word in $ALLOWEDROUNDS rounds to win."
        Write-host -NoNewLine "`nCorrect letters in the correct position will be "; write-host -foregroundcolor green "green"
        Write-host -NoNewLine "Correct letters in an incorrect position will be "; write-host -foregroundcolor yellow "yellow"
        Write-host -NoNewLine "Letters that do not appear in the word will be "; write-host -foregroundcolor gray "gray"
        Write-host "`nGood luck!`n"
    }

    #verbose output
    if ($GuessObjectArray){
        Write-Verbose "Remaining Letters in guess:"
        Write-VerboseResults -Word $GuessObjectArray -verbose:$VerbosePreference
    }
    if ($WordObjectArray){
        Write-Verbose "Remaining Letters in word to guess:"
        Write-VerboseResults -Word $WordObjectArray -verbose:$VerbosePreference
    }
    if ($ResultObjectArray){
        Write-Verbose "Letters found after exact match search:"
        Write-VerboseResults -Word $ResultObjectArray -verbose:$VerbosePreference
    }
    
    #After exact matches look for correct letters in the wrong spot from the remaining letters
    foreach ($letter in $GuessObjectArray){
        if (Test-CorrectPlacement -Letter $letter.Letter -Position $letter.Position -Word $WordObjectArray -Contains){
            #add found letter to result object array
            $properties = @{
                'Letter' = $letter.Letter;
                'Position' = $letter.Position;
                'FoundExact' = $False;
                'FoundContains' = $True;
            }
            Write-Verbose "Contains match on [$($letter.letter)] in position [$($letter.position)]"
            $ResultObjectArray += New-Object -TypeName PSObject -Prop $properties

            #remove letter from guess object array (since it is already found you don't want to guess it again)
            Write-Verbose "Removing [$($letter.letter)] in position [$($letter.position)] from guess object array"
            $ObjToRemove = $GuessObjectArray | where-object {$_.Position -eq $letter.Position}
            $GuessObjectArray = $GuessObjectArray | Where-Object {$_ -ne $ObjToRemove}

            #remove letter from word object array (since it is already found you don't want to find it again)
            Write-Verbose "Removing [$($letter.letter)] in position [$($letter.position)] from word object array"
            $ObjToRemove = ($WordObjectArray | where-object {$_.Letter -eq $letter.Letter})[0] #only remove the first one found
            $WordObjectArray = $WordObjectArray | Where-Object {$_ -ne $ObjToRemove}
        }
    }

    #verbose output
    if ($GuessObjectArray){
        Write-Verbose "Remaining Letters in guess:"
        Write-VerboseResults -Word $GuessObjectArray -verbose:$VerbosePreference
    }
    if ($WordObjectArray){
        Write-Verbose "Remaining Letters in word to guess:"
        Write-VerboseResults -Word $WordObjectArray -verbose:$VerbosePreference
    }
    if ($ResultObjectArray){
        Write-Verbose "Letters found after contains search:"
        Write-VerboseResults -Word $ResultObjectArray -verbose:$VerbosePreference
    }

    #After match searches add remaining letters from guess to results array (showing they're not found)
    foreach ($letter in $GuessObjectArray){
    
        #add found letter to result object array
        $properties = @{
            'Letter' = $letter.Letter;
            'Position' = $letter.Position;
            'FoundExact' = $False;
            'FoundContains' = $False;
        }
        Write-Verbose "No match found for [$($letter.letter)] in position [$($letter.position)]"
        $ResultObjectArray += New-Object -TypeName PSObject -Prop $properties
    }
    
    #verbose output
    if ($ResultObjectArray){
        Write-Verbose "Letters found after test-guess:"
        Write-VerboseResults -Word $ResultObjectArray -verbose:$VerbosePreference
    }
    #Return results of guess
    $ResultObjectArray | Sort-Object Position
}

function Write-FormattedWord {
    [CmdletBinding()]
    Param (
        [PSCustomObject]$Word,
        [switch]$Hidden
    )
    $OutputLetterArray = @()
    foreach ($Letter in $Word){
        $LetterChar = $Letter.letter
            if ($Hidden){
                $LetterChar = [char]9632 #a box
            }
        if ($Letter.FoundExact){
            $properties = @{
                'Letter' = $LetterChar;
                'Color' = "green";
            }
            $OutputLetterArray += New-Object -TypeName PSObject -Prop $properties
        }
        elseif ($Letter.FoundContains){
            $properties = @{
                'Letter' = $LetterChar;
                'Color' = "yellow";
            }
            $OutputLetterArray += New-Object -TypeName PSObject -Prop $properties
        }
        else {
            $properties = @{
                'Letter' = $LetterChar;
                'Color' = "gray";
            }
            $OutputLetterArray += New-Object -TypeName PSObject -Prop $properties
        }
    }
    write-host "$($OutputLetterArray[0].Letter) " -NoNewLine -foregroundcolor $OutputLetterArray[0].color; write-host "$($OutputLetterArray[1].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[1].color); write-host "$($OutputLetterArray[2].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[2].color); write-host "$($OutputLetterArray[3].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[3].color); write-host "$($OutputLetterArray[4].Letter)" -foregroundcolor $($OutputLetterArray[4].color)  
}

function Write-LettersLists {
    [CmdletBinding()]
    Param (
        [PSCustomObject[]]$WordsArray
    )
    $usedLetters = @()
    $alphabet = [char[]](65..90)
    foreach ($word in $WordsArray){
        $usedLetters += $word | select-object -expandproperty letter
    }
    $usedLetters = $usedLetters | select-object -uniq | sort-object
    $unusedLetters = $alphabet | where-object {-not($_ -in $usedLetters)}

    write-host "`nUnused Letters:"
    $unusedLetters -join " "
}

#Initialize game - get word
$GameType = Get-GameType -verbose:$VerbosePreference
if ($GameType -eq "random"){
    $WordToGuess = Get-WordToGuess -verbose:$VerbosePreference
}
elseif ($GameType -eq "seed"){
    $seed = Get-Seed
    $WordToGuess = Get-WordToGuess -Seed $seed -verbose:$VerbosePreference
}

#start playing the game
$CurrentRound = 0
$WonGame = $False
$resultsArray = @()
Write-GameInstructions
while (($CurrentRound -lt $ALLOWEDROUNDS) -and (-not($WonGame))){
    $CurrentRound += 1
    if ($CurrentRound -eq $ALLOWEDROUNDS){
        $GameOver = $True
    }
    $guess = Get-Guess -verbose:$VerbosePreference
    clear-host
    $result = Test-Guess -Guess $guess -Word $WordToGuess -verbose:$VerbosePreference
    $resultsArray += @(,$result)
    foreach ($round in $resultsArray){
        Write-FormattedWord -word $round
    }
    if ((($result | select-object -uniq FoundExact).FoundExact.count -eq 1) -and (($result | select-object -uniq FoundExact).FoundExact[0])){
        $WonGame = $True
        $GameOver = $True
        Write-Host "`nYou win! Yay!`n"
    }
    If(-Not($GameOver)){ #show letter list only if game isn't over
        Write-LettersLists -WordsArray $resultsArray
    }
}
if (-not($WonGame)){
    Write-Host "`nYou lose. Shoot. The word was [$WordToGuess]`n"
}

#Show Final Results
if ($Seed){
    Write-host "Wordle $seed $CurrentRound/$ALLOWEDROUNDS"
}
else {
    Write-host "Wordle $CurrentRound/$ALLOWEDROUNDS"
}
foreach ($round in $resultsArray){
    Write-FormattedWord -word $round -Hidden
}
$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null