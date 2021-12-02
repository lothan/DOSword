## DOSword

A generator of COM+PUZ polyglots. Turn your favorite (mini) crossword into a standalone DOS program, while keeping it a valid .PUZ file. Crossword solving program written in 8086 assembly. Tested using DOSBox

To build, rename your .puz to be `input.puz` and run `make`. If you have DOSBox installed, `make test-com` loads and executes the generated COM file. Maximum puzzle size is 5x5 and a sample puzzle is provided.

Extensive feature set includes:
* Win Condition
* Automatically go to the next cell (to the right)
* Free version allows for up to 10 Clues!
* Dark Theme (only)

![A small video showing the DOS program running](https://github.com/lothan/DOSword/blob/main/demo.gif)

Originally was hoping to have this fit in the 512 bytes of a MBR boot sector, but the average mini puzzles from the NYT are over 250 bytes. So something like half of the boot sector has to be taken up by the PUZ file. The code to just print the puzzle and calculate the correct clue numberings took over 200 bytes, which didn't leave a lot of room to actually play the puzzle. This is my first time programming in assembly and real mode, so there is certainly big space savings, but I didn't know if there was enough and didn't want to spend endless hours trying to find it. So in the end I changed it to a playable COM file.
