# PSWordle
## Wordle in PowerShell
### Launching Wordle
Launch by downloading the code, opening PowerShell to the directory it is in, and running:
`Start-Wordle`
This will launch a game with a random word to guess and six attempts to do so.

Alternatively, you can set the number of rounds. To change it to 4 rounds, for example, run: 
`Start-Wordle -ALLOWEDROUNDS 4` 

### Seeding the random word
When Wordle starts you are prompted to run a fully random game or to seed the game with an integer. Using a common seed would allow multiple people to play the same game.

