# PSWordle
## Wordle in PowerShell
Wordle is a word guessing game popularized from https://www.powerlanguage.co.uk/wordle. This is a PowerShell version of the same game.

### Launching Wordle
First, download the `start-wordle.ps1` file and open PowerShell to the directory it is downloaded to. One way to open PowerShell to the directory the script is in is to navigate to that folder in Windows Explorer, type `PowerShell` into the address bar, and press 'Enter.'

Once you are in the correct directory run the following PowerShell command:

`.\Start-Wordle.ps1`

This will launch a game with a random word to guess and six attempts to do so.

### Seeding the random word
When Wordle starts you are prompted to run a fully random game or to seed the game with an integer. Using a common seed would allow multiple people to play the same game.

### Changing the number of guesses
You can change the number of guesses you get before losing the game. To change it to 4 rounds of guesses, for example, run: 

`.\Start-Wordle.ps1 -AllowedRounds 4` 

### Changing the letter colors
By default, the letters are green if they are correct, yellow if they're in the wrong position, and gray if they do not appear in the word. For accessibility these colors can be changed. Example:

`.\Start-Wordle.ps1 -LetterInCorrectSpotColor blue -LetterInWrongSpotColor yellow -LetterNotInWordColor red`
