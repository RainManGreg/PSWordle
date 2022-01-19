[CmdletBinding()]
    param(
        [ValidateScript({$_ -gt 0})] #Can't have fewer than 1 round in the game
        [int]$AllowedRounds = 6,

        [ValidateSet("Black",
            "DarkBlue",
            "DarkGreen",
            "DarkCyan",
            "DarkRed",
            "DarkMagenta",
            "DarkYellow",
            "Gray",
            "DarkGray",
            "Blue",
            "Green",
            "Cyan",
            "Red",
            "Magenta",
            "Yellow",
            "White"
        )]
        [string]$LetterInCorrectSpotColor = "green",

        [ValidateSet("Black",
            "DarkBlue",
            "DarkGreen",
            "DarkCyan",
            "DarkRed",
            "DarkMagenta",
            "DarkYellow",
            "Gray",
            "DarkGray",
            "Blue",
            "Green",
            "Cyan",
            "Red",
            "Magenta",
            "Yellow",
            "White"
        )]
        [string]$LetterInWrongSpotColor = "yellow",

        [ValidateSet("Black",
            "DarkBlue",
            "DarkGreen",
            "DarkCyan",
            "DarkRed",
            "DarkMagenta",
            "DarkYellow",
            "Gray",
            "DarkGray",
            "Blue",
            "Green",
            "Cyan",
            "Red",
            "Magenta",
            "Yellow",
            "White"
        )]
        [string]$LetterNotInWordColor = "darkgray"
    )

function Get-Dictionary {
<#
.DESCRIPTION
Retrieves a dictionary of 5 letter words.

.OUTPUTS
An array of all 5 letter words in the dictionary
#>
    (invoke-webrequest -URI https://raw.githubusercontent.com/charlesreid1/five-letter-words/master/sgb-words.txt).content.split("`n") | where-object {$_ -ne ""}
}

function Get-WordToGuess {
<#
.DESCRIPTION
Retrieves a random word from the dictionary (using Get-Dictionary). Optional 'Seed' parameter can be passed to seed the randomizer.

.OUTPUTS
A random word from the dictionary
#>
	[CmdletBinding()]
    param(
        [int]$Seed
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
<#
.DESCRIPTION
Validates that a guess is in the dictionary

.OUTPUTS
$True if the guess is in the dictionary - $False otherwise
#>
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
<#
.DESCRIPTION
Validates that the guess is 5 letters long.

.OUTPUTS
$True if the guess is 5 letters long - $False otherwise
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Guess
    )
    write-verbose "Length of guess is [$($Guess.length)]"
    $Guess.length -eq 5
}

function Get-Guess {
<#
.DESCRIPTION
Retrieves a valid 5 letter guess from the player. Runs tests to validate the guess.

.OUTPUTS
A valid 5 letter guess from the player
#>
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
<#
.DESCRIPTION
Gets an integer from the player to be used as the randomizer seed.

.OUTPUTS
An integer to be used as the randomizer seed
#>
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
<#
.DESCRIPTION
Asks the player whether to do a fully random word to guess or to seed the randomizer. 

.OUTPUTS
"random" for a fully random word to guess - "seed" for a game with a seeded randomizer
#>
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
<#
.DESCRIPTION
Tests whether a letter is in the provided $Word object. By default looks for exact matches. "Contains" switch can be used to look for the letter anywhere in the word.

.OUTPUTS
$True or $False
#>
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
<#
.DESCRIPTION
Creates an array of custom objects representing letters in a word. Properties are "Letter": the letter, and "Position": position in the word (0-5)

.OUTPUTS
An array of custom objects representing letters in a word
#>
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
<#
.DESCRIPTION
Writes verbose output to troubleshoot game logic if "verbose" flag is used

.OUTPUTS
Verbose output
#>
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
<#
.DESCRIPTION
Takes a provided guess and checks it against the provided word. Both are strings. Returns array of custom objects representing the results of the check.
Attributes of the custom objects are:
"Letter" : the letter that was guessed
"Position" : the position of the letter in the word (0-5)
"FoundExact" : $True if the letter and position match the word to guess. $False otherwise.
"FoundContains" : $True if the letter is in the word to guess but the position is incorrect. $False otherwise

.OUTPUTS
An array of custom objects describing the results of the guess
#>
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

    #Start with searching for exact matches
    foreach ($letter in $GuessObjectArray){
        if (Test-CorrectPlacement -Letter $letter.Letter -Position $letter.Position -Word $WordObjectArray){
            #add found letter to result object array
            $properties = @{
                'Letter' = $letter.Letter;
                'Position' = $letter.Position;
                'FoundExact' = $True; #indicates that the letter and position were correct
                'FoundContains' = $False; #the letter and position were correct, so this is $False
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

    #verbose output
    if ($GuessObjectArray){
        Write-Verbose "Remaining Letters in guess:"
        Write-VerboseResults -Word $GuessObjectArray 
    }
    if ($WordObjectArray){
        Write-Verbose "Remaining Letters in word to guess:"
        Write-VerboseResults -Word $WordObjectArray 
    }
    if ($ResultObjectArray){
        Write-Verbose "Letters found after exact match search:"
        Write-VerboseResults -Word $ResultObjectArray 
    }
    
    #After exact match lookup, look for correct letters in the wrong spot from the remaining letters
    foreach ($letter in $GuessObjectArray){
        if (Test-CorrectPlacement -Letter $letter.Letter -Position $letter.Position -Word $WordObjectArray -Contains){
            #add found letter to result object array
            $properties = @{
                'Letter' = $letter.Letter;
                'Position' = $letter.Position;
                'FoundExact' = $False; #indicates that the letter and position were incorrect
                'FoundContains' = $True; #indicates that the letter is in the word but the position was incorrect
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
        Write-VerboseResults -Word $GuessObjectArray 
    }
    if ($WordObjectArray){
        Write-Verbose "Remaining Letters in word to guess:"
        Write-VerboseResults -Word $WordObjectArray 
    }
    if ($ResultObjectArray){
        Write-Verbose "Letters found after contains search:"
        Write-VerboseResults -Word $ResultObjectArray 
    }

    #After match searches add the remaining letters from the guess to results array (indicating that they're not found)
    foreach ($letter in $GuessObjectArray){
    
        #add found letter to result object array
        $properties = @{
            'Letter' = $letter.Letter;
            'Position' = $letter.Position;
            'FoundExact' = $False; #indicates that the letter and position were incorrect
            'FoundContains' = $False; #indicates that the letter is not found in the word
        }
        Write-Verbose "No match found for [$($letter.letter)] in position [$($letter.position)]"
        $ResultObjectArray += New-Object -TypeName PSObject -Prop $properties
    }
    
    #verbose output
    if ($ResultObjectArray){
        Write-Verbose "Letters found after test-guess:"
        Write-VerboseResults -Word $ResultObjectArray 
    }

    #Return results of the guess and put the letters in the correct order
    $ResultObjectArray | Sort-Object Position
}

function Write-GameInstructions {
<#
.DESCRIPTION
Writes the instructions for the game to the console

.OUTPUTS
Instructions for the game written to console
#>
    clear-host
    Write-host "Welcome to Wordle!"
    Write-host "Guess the five letter word in $ALLOWEDROUNDS rounds to win."
    Write-host -NoNewLine "`nCorrect letters in the correct position will be "; write-host -foregroundcolor $LetterInCorrectSpotColor "$LetterInCorrectSpotColor"
    Write-host -NoNewLine "Correct letters in an incorrect position will be "; write-host -foregroundcolor $LetterInWrongSpotColor "$LetterInWrongSpotColor"
    Write-host -NoNewLine "Letters that do not appear in the word will be "; write-host -foregroundcolor $LetterNotInWordColor "$LetterNotInWordColor"
    Write-host "`nGood luck!`n"
}
function Write-FormattedWord {
<#
.DESCRIPTION
Writes the word out to the console using the green/yellow/gray colors indicating the guess results. "Word" input is the array returned by "Test-Guess." 
Optional "Hidden" switch shows the colors but hides the letters (shown at the end of the game)

.OUTPUTS
Word to the console in colors indicating guess results
#>

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
                'Color' = $LetterInCorrectSpotColor;
            }
        }
        elseif ($Letter.FoundContains){
            $properties = @{
                'Letter' = $LetterChar;
                'Color' = $LetterInWrongSpotColor;
            }
        }
        else {
            $properties = @{
                'Letter' = $LetterChar;
                'Color' = $LetterNotInWordColor;
            }
        }
        $OutputLetterArray += New-Object -TypeName PSObject -Prop $properties
    }
    write-host "$($OutputLetterArray[0].Letter) " -NoNewLine -foregroundcolor $OutputLetterArray[0].color; `
    write-host "$($OutputLetterArray[1].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[1].color); `
    write-host "$($OutputLetterArray[2].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[2].color); `
    write-host "$($OutputLetterArray[3].Letter) " -NoNewLine -foregroundcolor $($OutputLetterArray[3].color); `
    write-host "$($OutputLetterArray[4].Letter)" -foregroundcolor $($OutputLetterArray[4].color)  
}

function Write-LettersLists {
    <#
    .DESCRIPTION
    Writes the keyboard layout showing letters in colors corresponding with the guesses thus far. Letters calculated from array of results returned by each subsequent "test-guess"
    .OUTPUTS
    Keyboard showing letters in the colors corresponding with their guess status
    #>
    [CmdletBinding()]
    Param (
        [PSCustomObject[]]$WordsArray
    )
    $usedLetters = @()
    $keyboardTopRow = @("Q","W","E","R","T","Y","U","I","O","P")
    $keyboardMiddleRow = @("","A","S","D","F","G","H","J","K","L")
    $keyboardBottomRow = @("  ","Z","X","C","V","B","N","M")
    $keyboardLayout = @($keyboardTopRow, $keyboardMiddleRow, $keyboardBottomRow)
    foreach ($word in $WordsArray){
        #$usedLetters += $word | select-object -expandproperty letter
        foreach ($Letter in $Word){
            $LetterChar = $Letter.letter
            if ($Letter.FoundExact -or $Letter.FoundContains){
                $properties = @{
                    'Letter' = $LetterChar;
                    'Color' = $LetterInCorrectSpotColor;
                }
            }
            else {
                $properties = @{
                    'Letter' = $LetterChar;
                    'Color' = $LetterNotInWordColor;
                }
            }
            $obj = New-Object -TypeName PSObject -Prop $properties
            if (-not($obj.letter -in $UsedLetters.letter)){
                $usedLetters += $obj
            }
        }
    }

    #write output
    write-host "`n    Keyboard:"
    foreach ($row in $keyboardLayout){
        foreach ($letter in $row){
            if ($letter -in $usedLetters.letter){
                $letterObj = $usedLetters | where-object {$_.letter -eq $letter} 
                write-host "$($letterObj[0].Letter) " -NoNewLine -foregroundcolor $letterObj[0].color
            }
            else {
                write-host "$letter " -NoNewLine 
            }
        }
        write-host ""
    }
   # write-host "`n"
}

#Initialize game - get word
$GameType = Get-GameType 
if ($GameType -eq "random"){
    $seed = get-random 
    $WordToGuess = Get-WordToGuess -seed $seed
}
elseif ($GameType -eq "seed"){
    $seed = Get-Seed
    $WordToGuess = Get-WordToGuess -Seed $seed 
}

#start playing the game
$CurrentRound = 0
$WonGame = $False
$resultsArray = @()

Write-GameInstructions
while (($CurrentRound -lt $ALLOWEDROUNDS) -and (-not($WonGame))){
    $CurrentRound += 1
    if ($CurrentRound -eq $ALLOWEDROUNDS){ #last round is over so the game is over one way or the other
        $GameOver = $True
    }
    $guess = Get-Guess 
    clear-host

    $result = Test-Guess -Guess $guess -Word $WordToGuess 
    $resultsArray += @(,$result) #keep track of all the guesses in an array of arrays
    write-host "Round $CurrentRound/$ALLOWEDROUNDS"
    foreach ($round in $resultsArray){ #write out all the guesses so far
        Write-FormattedWord -word $round
    }

    if ((($result | select-object -uniq FoundExact).FoundExact.count -eq 1) -and (($result | select-object -uniq FoundExact).FoundExact[0])){ #if every letter is in the exact right position the player won
        $WonGame = $True
        $GameOver = $True
        Write-Host "`nYou win! Yay!`n"
    }
    If(-Not($GameOver)){ #show unguessed letter list only if game isn't over
        Write-LettersLists -WordsArray $resultsArray
    }
}
if (-not($WonGame)){
    Write-Host "`nYou lose. Shoot. The word was [$WordToGuess]`n"
}

#Display Final Results
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