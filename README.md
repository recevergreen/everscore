# everscore
a network streaming virtual scoreboard and score bug

This is a utility we use at The Evergreen State College to enable our Daktronics scoreboard to drive a custom prerendered raytraced score bug. In our current livestream configuration, the streaming computer and camera are situated at the top of the bleachers, while the scoreboard and game management computer are at the courtside game table. This distance is too long to run a physical cable, so we connect the scoreboard hardware controller to the game management computer, which is running everscore, render the score bug, and stream a 960x540 feed of that score bug over the network via NDI to the streaming computer, which recieves the NDI feed and displays it in an overlay in OBS. This solution enables everscore to be used with any game streaming platform that supports NDI.

# Requirements
- pyserial
- scorebox-consoles
- libNDI
- ndi-python
- DistroAV (for recieving the NDI stream in OBS)

# Roadmap
This tool is still in development and still lacks critical user interface elements for features like team customization, manual control and IP address identification and diagnostics. There is currently a bug that causes the software to behave unpredictably if hidden, closed, or minimized. Once these issues are resolved and the tool is ready to be used in production, the following additional features are in the roadmap:

- Basketball Mode - Summer 2025
- Volleyball Mode - Fall 2025
- Wrestling Mode - Fall 2025
- Alternate SDR (software defined radio) Mode - Fall 2026
- Soccer Mode - Fall 2026
