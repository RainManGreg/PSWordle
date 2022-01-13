# PSWordle
## Wordle in PowerShell. 
Launch by downloading the code, opening PowerShell to the directory it is in, and running:
`Start-Wordle`
This will launch a game with a random word to guess.

Alternatively, the randomized word to guess can be seeded with an integer so multiple people can play the same game. For example, to do this with a seed of 100, run: 
`Start-Wordle -Seed 100` 