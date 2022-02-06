# PSWordle
## Wordle in PowerShell
Wordle is a word guessing game popularized from https://www.powerlanguage.co.uk/wordle. This is a PowerShell version of the same game, but it can be played more than once per day!

### Launching Wordle
First, download the `start-wordle.ps1` file and open PowerShell to the directory it is downloaded to. One way to open PowerShell to the directory the script is in is to navigate to that folder in Windows Explorer, type `PowerShell` into the address bar, and press 'Enter.'

Once you are in the correct directory run the following PowerShell command:

`.\Start-Wordle.ps1`

This will launch a game with a random word to guess and six attempts to do so.

![The beginning of a Wordle game](/assets/images/WordleStart.png)

### A Wordle Guess Round

Each round you see the results of your previous guesses in the colors of the letters, as well as the keyboard layout with the colors filled in to aid in your next guess.

![A round of Wordle](/assets/images/WordleGuess2.png)

### Winning the Wordle Game

You win if you guess the word before the maximum number of guesses is reached. By default this is 6 rounds of guesses.

![A game of Wordle](/assets/images/ExampleGameOutput.png)

## Modifying the game
### Seeding the random word
When Wordle starts you are prompted to run a fully random game or to seed the game with an integer. Using a common seed would allow multiple people to play the same game.

### Hard Mode
You can play Wordle with a dictionary with approximately twice as many words to make the game more difficult.

`.\Start-Wordle.ps1 -HardMode`

### Changing the number of guesses
You can change the number of guesses you get before losing the game. To change it to 4 rounds of guesses, for example, run: 

`.\Start-Wordle.ps1 -AllowedRounds 4` 

### Changing the letter colors
By default, the letters are green if they are correct, yellow if they're in the wrong position, and gray if they do not appear in the word. For accessibility these colors can be changed. Example:

`.\Start-Wordle.ps1 -LetterInCorrectSpotColor blue -LetterInWrongSpotColor yellow -LetterNotInWordColor red`

## Using Solvers

You can use `-cheat` to use a solver. Choose the algorithm with `-algorithm`. Choose which word to be the solver's initial guess with `-FirstWord`. Run a simulation with reduced console output with `-Simulation`... it will return results in a PS object. 

### Choosing the random word to guess
Choose the word you want to guess with `-WordToGuess`. This is useful for testing out the solver algorithms. 

### Word selection algorithm plugin
An alternative version of wordle is `.\Start-Wordle-AlgInput.ps`. You can pass in a script that chooses the word to guess from a list of possible words with the `-AlgorithmPath` parameter. Include the path to the file in `-AlgorithmPath`.

The script passed in requires a `-PossibleWords` parameter that is an array of words to choose one from and return a single word to be the guess. It also requires the input of a `-WordsArray` parameter, which is an array of PSObjects. Each PSObject in the array represents the results of a guessed word (each letter and whether it was green, yellow, or gray). Each PSObject has the following properties to do this:
- `Letter` : the letter that was guessed
- `Position` : the position of the letter in the word (0-5)
- `FoundExact` : $True if the letter and position match the word to guess. $False otherwise.
- `FoundContains` : $True if the letter is in the word to guess but the position is incorrect. $False otherwise.

## Play the game with help

You can use the `-Help` parameter to get some help from a solver algorithm with the `Start-Wordle-AlgInput.ps1` version. `-AlgorithmPath` is required. You will get a list of possible words to choose from. Note that it will turn off if you guess a list from outside the list.

## Judging your game

You can use the `-Judge` parameter to judge one of your previous games. `-WordToGuess` is required, as is `WordsGuessed`, which is the list of words you guessed in order. Note that it will fail if you guessed an invalid word based on your clues at the time of the guess.

## Troubleshooting

If you get an error that start-wordle.ps1 is not digitally signed you may need to change your PowerShell execution policy first:

`Set-ExecutionPolicy Bypass -Scope CurrentUser`

Be careful when running any unsigned code though!
