# ranch-rangers
This is a little Famicom/NES turn-based strategy game featuring two feuding farmers and their frequent fights! They pit all the farm animals against each other in feud after feud! You can play against the computer or against a friend, building farms to collect money to buy more animals. Each animal has a unique attack method- cows charge forward in straight lines, and chickens shoot eggs diagonally. You must also defend yourself, the hard working farmer, from being attacked by your rival's animals, or it's all over for you!

![image](https://i.imgur.com/tpRMLNh.png)

The idea is to make something which is netplayable over an emulator that supports multiplayer like [Mesen](https://www.mesen.ca/) or [Nestopia](http://nestopia.sourceforge.net/). The turn-based nature lets it be fully playable with lag or ping disparities. This game is very small (NROM 128 = 24KiB total)!

Uses the [Famitone 4.1 audio library](https://github.com/nesdoug/famitone4.1) by shiru and nesdoug. BCD algorithm and prng are from the [nesdev wiki-](http://wiki.nesdev.com/w/index.php/Nesdev_Wiki) direct citation/linkage in respective files where the code is used.
