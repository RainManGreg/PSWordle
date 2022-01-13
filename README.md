# PSWordle
## Wordle in PowerShell
### Launching Wordle
First, download the `start-wordle.ps1` file and open PowerShell to the directory it is downloaded to. One way to open PowerShell to the directory the script is in is to navigate to that folder in Windows Explorer, type `PowerShell` into the address bar, and press 'Enter.'

Once you are in the correct directory run the following PowerShell command:

`.\Start-Wordle.ps1`

This will launch a game with a random word to guess and six attempts to do so.

You can change the number of guesses you get before losing the game. To change it to 4 rounds of guesses, for example, run: 

`.\Start-Wordle.ps1 -ALLOWEDROUNDS 4` 

### Seeding the random word
When Wordle starts you are prompted to run a fully random game or to seed the game with an integer. Using a common seed would allow multiple people to play the same game.

