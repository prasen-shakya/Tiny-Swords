# Tiny Swords
<img width="1512" height="853" alt="image" src="https://github.com/user-attachments/assets/cf3542a0-6740-47e6-843e-09a355b66579" />

Tiny Swords is a 2D top-down arena survival game built with Godot 4.6. You control a sword fighter, survive increasingly large enemy waves, and loop through a simple menu -> gameplay -> game over flow with scene transitions.

## Overview

- Engine: Godot 4.6
- Genre: 2D arena survival / wave defense
- Main scene flow: `scene_handler.tscn` -> main menu -> `main.tscn` -> end game screen
- Input: keyboard movement plus a single attack action

Each round heals the player, increases the enemy count, and spawns a mix of enemies from configured spawn zones. The current round and remaining enemies are shown in the HUD.

## Controls

- `WASD` or arrow keys: move
- `Space`: attack
