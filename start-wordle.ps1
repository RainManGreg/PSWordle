[CmdletBinding(DefaultParameterSetName='Seed')]
    param(
        [Parameter(ParameterSetName = 'Seed')]
        [int]$Seed = (get-date).dayofyear + (get-date).year,

        [Parameter(ParameterSetName = 'Random')]
        [switch]$Random,

        [Parameter(ParameterSetName = 'SuppliedWord')]
        [string]$WordToGuess,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [switch]$Cheat,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [ValidateSet("Original","NoPointsForLockedLetters", "PositionScoring", "ComboScoring", "ComboScoringOptimized")]
        [string]$Algorithm = "Original",

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [switch]$Simulation,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [string]$FirstWord,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [switch]$HardMode,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
        [ValidateScript({$_ -gt 0})] #Can't have fewer than 1 round in the game
        [int]$AllowedRounds = 6,

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
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

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
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

        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'Seed')]
        [Parameter(ParameterSetName = 'SuppliedWord')]
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

function Get-WordToGuess {
<#
.DESCRIPTION
Retrieves a random word from the dictionary (using Get-Dictionary). 'Seed' parameter passed to seed the randomizer.

.OUTPUTS
A random word from the dictionary
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]    
        [int]$Seed,
        [switch]$HardMode
	)

    $Dictionary = Get-Dictionary -HardMode:$HardMode
    $ResultWord = $Dictionary | get-random -SetSeed $Seed
    
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
        [string]$Guess,
        [switch]$HardMode
    )
    $inDictionary = ($guess -in (Get-Dictionary -HardMode)) -or ($guess -in (Get-Dictionary))
    write-verbose "Guess is in dictionary: $inDictionary. HardMode value $HardMode"
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
    param(
        [switch]$HardMode
    )
    do{
        $guess = $NULL
        $guess = Read-Host "`nPlease enter your 5 letter guess: "
        if (-Not(Test-GuessLength -Guess $guess)){
            write-host "Invalid word length. Word must be 5 letters."
        }
        elseif (-Not(Test-GuessIsWord -Guess $guess -HardMode)){
            write-host "Invalid word. Please enter a valid word."
        }
        
    } until (((Test-GuessIsWord -Guess $guess -HardMode) -eq $True) -and ((Test-GuessLength -Guess $guess) -eq $True))
    $guess = $guess.toupper()
    write-verbose "Guessed word is [$guess]"
    $guess
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
   write-host ""
}

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
        [string]$Regex
    )

    $Dictionary = Get-Dictionary 
    $PossibleWords = $Dictionary | select-string -Pattern $Regex
    $ofs = " "
    write-verbose "Possible words: $PossibleWords"
    $PossibleWords
}

function Get-WordOrder_OG {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]  
        [string[]]$PossibleWords
    )

    $letterdict = @{}
    $worddict = @{}
    
    #build dictionary of letters/num times they occur
    foreach ($word in $PossibleWords){
        foreach ($Letter in $word.ToCharArray()){
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
        $score = 0
        foreach ($Letter in $word.ToCharArray()){
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
} 

function Get-WordOrder_NoPointsForLockedLetters {
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
} 

function Get-WordOrder_PositionScoring {
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
}

function Get-WordOrder_ComboScoring {
    #combines the two scoring methods
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
    $sortedByLetterPopularity_position = $worddict.GetEnumerator() | sort-object value -Descending | select-object -expandproperty key
    $ofs = ", "
    write-verbose "Best words according to letter position popularity: "
    foreach ($word in $sortedByLetterPopularity_position){
        write-verbose "$word : $($worddict[$word])"
    }
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
    #write-verbose "Dictionary keys: $($letterdict.Keys)"
   # write-verbose "Dictionary values: $($letterdict.Values)"
    foreach ($word in $PossibleWords){
        $allowedPositions = 0..4 | where-object {-Not($_ -in $lockedPositions)}
        $ofs = ""
        [string]$reducedWord = foreach ($num in $allowedPositions){
            $word[$num]
        }
        #write-verbose "Word after removing locked positions: $reducedWord"
        $score = 0
        foreach ($Letter in $reducedword.ToCharArray()){
            $score += $letterdict["$Letter"]
        }
        $worddict["$word"] = $worddict["$word"] + $score
    }

    foreach ($letter in $letterdict.keys){
        write-verbose "$letter : $($letterdict[$letter])"
    }

    #write-verbose "Word keys: $($worddict.keys)"
    #write-verbose "Word values: $($worddict.values)"

    $sortedByLetterPopularity_whole = $worddict.GetEnumerator() | sort-object value -Descending | select-object -expandproperty key
    $ofs = ", "
    write-verbose "Best words according to letter popularity through the whole word: "
    foreach ($word in $sortedByLetterPopularity_whole){
        write-verbose "$word : $($worddict[$word])"
    }
    if ($sortedByLetterPopularity.count -ne 1){ 
        $scoredict = @{}
        #give each word a score based on its position in each list. 1 point for best word, 2 for second best, etc... Will rank by lowest overall score at end
        #get scores from position scoring
        $count = 1
        foreach ($word in $sortedByLetterPopularity_position){
            $scoredict[$word] = $count
            $count += 1
        }
        #get scores from total word scoring
        $count = 1
        foreach ($word in $sortedByLetterPopularity_whole){
            $scoredict[$word] = $Scoredict[$word] + $count
            $count += 1
        }
        
        #rank them
        $sortedByLetterPopularity = $scoredict.GetEnumerator() | sort-object value | select-object -expandproperty key
        $bestWordByLetterPopularity = $sortedByLetterPopularity[0] 
        write-verbose "Final Ranking:"
        $sortedByLetterPopularityWholeObj = $scoredict.GetEnumerator() | sort-object value
        foreach ($word in $sortedByLetterPopularityWholeObj){
            write-verbose "$($word.key) $($word.value)"
        }


        $lockedPositions = @()

        foreach ($num in 0..4){
            $LetterChanged = $False
            #write-verbose "$($bestWordByLetterPopularity.gettype())"
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
}

function Get-WordOrder_ComboScoringOptimized {
    #combines the two scoring methods
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]  
        [string[]]$PossibleWords
    )

    #------------------------------------------position logic------------------------------------------------------
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
        }
        $worddict["$word"] = $score
    }
    $sortedByLetterPopularity_position = $worddict.GetEnumerator() | sort-object value -Descending | select-object -expandproperty key
    $ofs = ", "
    <# write-verbose "Best words according to letter position popularity: "
    foreach ($word in $sortedByLetterPopularity_position){
        write-verbose "$word : $($worddict[$word])"
    } #>

    #---------------------------------whole word logic------------------------------------
    $letterdict = @{}
    $worddict2 = @{}
    
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
    #write-verbose "Dictionary keys: $($letterdict.Keys)"
   # write-verbose "Dictionary values: $($letterdict.Values)"
    foreach ($word in $PossibleWords){
        $allowedPositions = 0..4 | where-object {-Not($_ -in $lockedPositions)}
        $ofs = ""
        [string]$reducedWord = foreach ($num in $allowedPositions){
            $word[$num]
        }
        #write-verbose "Word after removing locked positions: $reducedWord"
        $score = 0
        foreach ($Letter in $reducedword.ToCharArray()){
            $score += $letterdict["$Letter"]
        }
        $worddict2["$word"] = $worddict2["$word"] + $score
    }

    foreach ($letter in $letterdict.keys){
        write-verbose "$letter : $($letterdict[$letter])"
    }

    #write-verbose "Word keys: $($worddict.keys)"
    #write-verbose "Word values: $($worddict.values)"

    $sortedByLetterPopularity_whole = $worddict2.GetEnumerator() | sort-object value -Descending | select-object -expandproperty key
    $ofs = ", "
    <# write-verbose "Best words according to letter popularity through the whole word: "
    foreach ($word in $sortedByLetterPopularity_whole){
        write-verbose "$word : $($worddict2[$word])"
    } #>

    #------------------------------------combine the two scoring methods----------------------------------------------
    if ($sortedByLetterPopularity.count -ne 1){ 
        $scoredict = @{}
        #give each word a score based on its position in each list. 1 point for best word, 2 for second best, etc... Will rank by lowest overall score at end
        #get scores from position scoring
        $count = $rank = 1
        $previousScore = -1 #so it doesn't occur ever but is initialized
        Write-verbose "Rank scores based on position:"
        foreach ($word in $sortedByLetterPopularity_position){
            $score = $worddict[$word]
            if ($score -ne $previousScore){ #only increment the rank if it isn't a tie from last round
                $rank = $count
            }
            write-verbose "$word : $score : $rank"
            $scoredict[$word] = $rank
            $previousScore = $score
            $count += 1
        }

        #get scores from total word scoring
        $count = $rank = 1
        $previousScore = -1 #so it doesn't occur ever but is initialized
        Write-verbose "Rank scores based on whole word counts:"
        foreach ($word in $sortedByLetterPopularity_whole){
            $score = $worddict2[$word]
            if ($score -ne $previousScore){ #only increment the rank if it isn't a tie from last round
                $rank = $count
            }
            write-verbose "$word : $score : $rank"
            $scoredict[$word] = $scoredict[$word] + $rank
            $previousScore = $score
            $count += 1
        }
        
        #rank them
        $sortedByLetterPopularity = $scoredict.GetEnumerator() | sort-object value | select-object -expandproperty key
        $bestWordByLetterPopularity = $sortedByLetterPopularity[0] 
        write-verbose "Final Ranking:"
        $sortedByLetterPopularityWholeObj = $scoredict.GetEnumerator() | sort-object value
        foreach ($word in $sortedByLetterPopularityWholeObj){
            write-verbose "$($word.key) $($word.value)"
        }


        $lockedPositions = @()

        foreach ($num in 0..4){
            $LetterChanged = $False
            #write-verbose "$($bestWordByLetterPopularity.gettype())"
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
}

#Initialize game - get word
if ($HardMode){
    $HardModeText = "Hard Mode "
}

if ($Random){
    $seed = get-random 
}
if (-not($WordToGuess)){
    $WordToGuess = Get-WordToGuess -Seed $seed -HardMode:$HardMode
}
else{
    if ($HardMode){
        $dict = Get-Dictionary -HardMode
    }
    else{
        $dict = Get-Dictionary
    }
    if (-not($WordToGuess -in $dict)){
        throw "Invalid word [$($WordToGuess.toupper())]. It is not in the dictionary"
    }
}

#start playing the game
$CurrentRound = 0
$WonGame = $False
$resultsArray = @()
if (-not($Simulation) -and -not($Cheat)){
    Write-GameInstructions
}
while (($CurrentRound -lt $ALLOWEDROUNDS) -and (-not($WonGame))){
    $CurrentRound += 1
    if ($CurrentRound -eq $ALLOWEDROUNDS){ #last round is over so the game is over one way or the other
        $GameOver = $True
    }
    if (-not($suggestedGuess)){
        if (-not($Cheat)){
            $guess = Get-Guess -HardMode
        }
        else {
            if ($psboundparameters.containskey('FirstWord')){
                $guess = $FirstWord.toupper()
            }
            else{
                $guess = "ALERT" #the best guess supposedly
            }
        }
    }
    else {
        write-verbose $suggestedGuess
        $guess = $suggestedGuess

    }
    #clear-host

    $result = Test-Guess -Guess $guess -Word $WordToGuess 
    $resultsArray += @(,$result) #keep track of all the guesses in an array of arrays
    if (-not($Simulation)){
        write-host "Round $CurrentRound/$ALLOWEDROUNDS"
    }
    foreach ($round in $resultsArray){ #write out all the guesses so far
        if (-not($Simulation)){
            Write-FormattedWord -word $round
        }
    }

    if ((($result | select-object -uniq FoundExact).FoundExact.count -eq 1) -and (($result | select-object -uniq FoundExact).FoundExact[0])){ #if every letter is in the exact right position the player won
        $WonGame = $True
        $GameOver = $True
        if (-not($Simulation)){
            Write-Host "`nYou win! Yay!`n"
        }
    }
    If(-Not($GameOver)){ #show unguessed letter list only if game isn't over
        if (-not($Simulation) -and -not($Cheat)){
            Write-LettersLists -WordsArray $resultsArray
        }
        If ($Cheat){ #sometimes you want the computer to do the thinking
            $possiblewords = $suggestedGuessOrder = $suggestedGuess = $NULL
            $regex = Get-GuessHelpRegex -WordsArray $resultsArray
            $possiblewords = Get-GuessHelpPossibleWords -Regex $regex
            if ($possiblewords){
                if ($possiblewords.count -gt 1){  #only try to order them if there is more than one   
                    if ($Algorithm -eq "Original"){ 
                        $suggestedGuessOrder = Get-WordOrder_OG -PossibleWords $possiblewords
                    }
                    if ($Algorithm -eq "NoPointsForLockedLetters"){ 
                        $suggestedGuessOrder = Get-WordOrder_NoPointsForLockedLetters -PossibleWords $possiblewords
                    }
                    if ($Algorithm -eq "PositionScoring"){ 
                        $suggestedGuessOrder = Get-WordOrder_PositionScoring -PossibleWords $possiblewords
                    }
                    if ($Algorithm -eq "ComboScoring"){ 
                        $suggestedGuessOrder = Get-WordOrder_ComboScoring -PossibleWords $possiblewords
                    }
                    if ($Algorithm -eq "ComboScoringOptimized"){ 
                        $suggestedGuessOrder = Get-WordOrder_ComboScoringOptimized -PossibleWords $possiblewords
                    }
                
                    if ($suggestedGuessOrder.count -gt 1){
                        $suggestedGuess = $suggestedGuessOrder[0]
                    }
                    else{$suggestedGuess = $suggestedGuessOrder}
                }
                else { #if only one guess then guess it 
                    $suggestedGuess = $possiblewords
                }
            }
            else{
                write-verbose "No possible words found. D'oh"
            }
            
        }
    }
}

if (-not($WonGame)){
    if (-not($Simulation)){
        Write-Host "`nYou lose. Shoot. The word was [$WordToGuess]`n"
    }
    $returnScore = -1
}
else{
    $returnScore = $CurrentRound
}
#Display Final Results
if ($psboundparameters.containskey('Seed')){
    if (-not($Simulation)){
        Write-host "Wordle $AlgorithmText$HardModeText#$seed ($CurrentRound/$ALLOWEDROUNDS)"
    }
}
else {
    if (-not($Simulation)){
        Write-host "Wordle $AlgorithmText$HardModeText($CurrentRound/$ALLOWEDROUNDS)"
    }
}
foreach ($round in $resultsArray){
    if (-not($Simulation)){
        Write-FormattedWord -word $round -Hidden
    }
}
if ($Simulation){
    $guessedWords = foreach ($word in $resultsArray){
        $ofs = ""
        "$($word.letter)"
    } 
    if ($psboundparameters.containskey('Seed')){
        $properties = @{
            'Word' = $WordToGuess;
            'Score' = $returnScore;
            'GuessedWords' = $guessedWords;
            'Seed' = $seed
        }
    }
    else{
        $properties = @{
            'Word' = $WordToGuess;
            'Score' = $returnScore;
            'GuessedWords' = $guessedWords
        }
    }
    New-Object -TypeName PSObject -Prop $properties
}
