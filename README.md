<img width="1072" alt="Screenshot 2025-05-14 at 11 52 25 AM" src="https://github.com/user-attachments/assets/32117233-1a84-4fb5-ba0b-d1c74ccb10da" />

# everscore
a network streaming score bug

This is a utility developed at The Evergreen State College to generate a responsive scorebug graphic for use in a livestreamed soccer, basketball, volleyball, and wrestling event. It enables a Daktronics All Sport 5000 scoreboard to drive a custom prerendered raytraced score bug. The graphics were rendered in Blender and then converted into filmstrips for display. In our current livestream configuration, the streaming computer and camera are situated at the top of the bleachers, while the scoreboard and game management computer are at the courtside game table. This distance is too long to run a physical cable, so we connect the scoreboard hardware controller to the game management computer via a serial to USB adapter (which requires a kernel driver), which is running an instance of everscore. This game management computer sends the current game state to a receiving instance of everscore over the network via UDP. Both instances display a visual score bug. Game state data can be entered manually if the automatic stream from the scoreboard is not available or is malfunctioning. This manually entered game state data can also be streamed to another everscore instance via UDP. Our goal is to make this a very flexible tool for our live sports production needs at the college, while being simple enough for students to be able to use easily.

# Requirements
Releases do not have any required packages, but to edit the source code yourself you will need these python packages, ideally in a Python 3.13 environment:

- pyside6 (qt6)
- pyserial
- scorebox-consoles
- pyinstaller

# Roadmap
This tool is primarily intended for use in the context of The Evergreen State College athletics department, but once we have implented more customization features, it could easily be used in a variety of live sports productions at other institutions.

- Basketball Mode - Fall 2025
- Wrestling Mode - Winter 2025
- Radio control mode (with a high bandwidth software defined radio) - Studying feasibility
- Volleyball Mode - Fall 2026?
- Soccer Mode - Fall 2026?
