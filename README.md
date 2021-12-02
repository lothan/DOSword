## DOSword

A generator of COM+PUZ polyglots. Turn your favorite (mini) crossword into a standalone DOS program that can actually play the crossword, while keeping it a valid .PUZ file. Crossword solving program written in 8086 assembly. 

Extensive feature set includes:
* Win Condition
* Automatically go to the next cell (to the right)
* Free version allows for up to 10 Clues!
* Dark Theme (only)


Tested with DOSBox. Maximum puzzle size is 5x5 and a sample puzzle is provided. To build:

```
$ make
python3 prebuild.py input.puz crossword.asm
nasm -f bin crossword.asm -l crossword.com.list -Dcom=1 -o crossword.com.intermediate
Crossword COM code is 624 bytes long
cat input.puz crossword.com.intermediate > crossword.com
$ md5sum crossword.com
cbca7545719e73f2979d323071ad6cf6  crossword.com
$ make test-com
```

![A small video showing the DOS program running](https://github.com/lothan/DOSword/blob/main/demo.gif)

![A small video showing opening the same program in Across Lite as a valid PUZ file](https://github.com/lothan/DOSword/blob/main/acrosslite.gif)

Originally was hoping to have this fit in the 512 bytes of a MBR boot sector, but the average mini puzzles from the NYT are over 250 bytes. So unless I use a trivial 1x1 or 2x2 puzzle, most of the space for code is taken up by the PUZ file. The code to calculate the correct clue numbering and print the puzzle took over 200 bytes, which didn't leave a lot of room to actually play the puzzle. This is my first time programming in assembly and real mode, so there is certainly big space savings, but I didn't know if it would be enough to be feasible as an MBR. So halfway through making this, I changed it to COM file and stopped caring about space requirements.