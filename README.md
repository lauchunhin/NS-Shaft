# NS Shaft: Platform Pursuit

Welcome to the repository of **NS Shaft**, an exciting platform game written in assembly language. This game is a thrilling journey of agility and quick reflexes, where the player navigates through moving platforms.


## Project Description
This project aims to recreate the NS-Shaft game using the MIPS assembly language. The goal is to replicate the original game’s mechanics and gameplay as closely as possible, while also taking advantage of the unique features and capabilities of the MIPS architecture. NS-Shaft is a platform game where the player attempts to descend into a cave. These platforms move upwards at a slowly accelerating speed. At the top of the screen is a set of spikes. The goal of the game is to drop from one platform to another fast enough to avoid being hit by the spikes, but slow enough not to fall off the bottom of the screen.

## Language Used

This game is implemented in **MIPS Assembly Language**. MIPS (Microprocessor without Interlocked Pipelined Stages) is a reduced instruction set computer (RISC) instruction set architecture (ISA) developed by MIPS Computer Systems. 


## Game Mechanics

The core game logic revolves around the following key procedures:

1. **Player Movement**: The player runs on a platform or falls in the air. The player's movement is a crucial part of the game, determining the success of navigating through the platforms.

2. **Platform Movement**: The platforms move up and new platforms are generated when needed. This keeps the game dynamic and challenging.

3. **Player Hurt Recover**: If the player gets hurt by spines, they recover after some time. This adds an element of danger and recovery to the game.

4. **Unstable Platform Break**: If the player jumps on an unstable platform, the platform breaks after a short time. This introduces an element of unpredictability and requires quick decision-making from the player.

5. **Screen Refresh**: The screen is refreshed regularly to keep the game state updated.

## Dive In

Feel free to explore the code, understand its workings, and even contribute to enhancing this thrilling platform pursuit. Happy gaming!
