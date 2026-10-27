# Battle Realms Zen Edition Trainer (+8) <br>[ONLY DOWNLOAD THE ZENTRAINER.EXE]<br> 

A modernized, standalone memory trainer for **Battle Realms: Zen Edition (v1.59.1)**.

Reverse-engineered and re-architected as the modern successor to ICECHEAT's classic 2001 *Battle Realms Trainer +8 (V1.02)*. Built in C# (.NET 9.0) using native Windows memory APIs with ASLR support and local-player ownership isolation.

---

## Features & Controls

| Hotkey | Feature | Type | Description |
| :---: | :--- | :---: | :--- |
| **`F1`** | **Fill Resources** | Toggle | Continuously fills Rice and Water to your storage capacity. |
| **`F2`** | **Create Peasant** | Hotkey | Instantly advances spawn timers on your Peasant Huts to create peasants. |
| **`F3`** | **Reveal Map** | Toggle | Toggles Fog of War on/off cleanly with zero remote-thread flooding. |
| **`F4`** | **Build / Heal Building** | Hotkey | Instantly completes construction (100%), restores full HP, and clears all fire damage. |
| **`F5`** | **Instant Train / Upgrade** | Toggle | Accelerates unit training and technique upgrades (including Warlock's Tower). |
| **`F6`** | **+10 Yin Points** | Hotkey | Adds 10 Yin battle points to your pool. |
| **`F7`** | **+10 Yang Points** | Hotkey | Adds 10 Yang battle points to your pool. |
| **`F8`** | **Unit Limit 500** | Toggle | Sets unit cap to 500; toggling OFF dynamically restores your scenario's configured cap. |
| **`Ctrl+F12`**| **Exit Trainer** | Hotkey | Safely turns off active toggles, restores game defaults, and exits. |

---

## Key Improvements & Technical Fixes

### 1. Player Ownership Isolation (AI Enemies Excluded)
In standard RTS engines, scanning all entity slots affects both player and enemy buildings. This trainer uses the engine's true player ownership slot offset:
* **`[entity + 0x84] == localPlayerId`**: The engine's true player slot ID (`0` to `7`) in all campaign missions and skirmish matches (where `localPlayerId = [pPlayer + 0x6C]`).
* **Result**: `Create Peasant (F2)`, `Instant Train (F5)`, and `Build/Heal (F4)` strictly isolate their effects to the local human player. AI opponents across all 7 rival slots never receive free peasants, instant training, or automatic repairs.

### 2. Transition-Safe Fog of War (Reveal Map)
The original remote call executes `DisableFogOfWar` (`Base + 0xDA029`) and `EnableFogOfWar` (`Base + 0xDA01C`). Rather than running inside the 50ms tick loop (which crashed the engine during chapter transitions), it is executed **once** per toggle action with validation checks against the player controller.

### 3. Proper Building Construction & Extinguishment Logic
* **HP**: Stored as 16.16 fixed-point at `+0x88` (Max HP) and `+0x8C` (Current HP).
* **Construction & Foundation Completion (One-Tap Finish)**:
  * For structures under construction (`[bldg + 0xCC] == 0`), F4 advances building HP to 99.9% (just 0.5 HP short of completion) and sets progress (`+0x90`) to 99.6%.
  * Exactly **one tap/strike** from a peasant's hammer crosses 100% naturally. This allows the game engine to fire its native completion event, play the *"Build Complete"* announcement, and register full player ownership and UI buttons without desyncing.
* **Fire System & Repairs**: For completed structures, F4 restores 100% HP, resets accumulated fire ticks (`+0x80 = 0`), and clears active flame emitters (`+0x2E8 = 0`).

### 4. Dynamic Scenario Population Cap Restoration
Rather than hardcoding arbitrary limits (such as 20 or 30):
* When toggled ON, the trainer captures the live game cap.
* If launched mid-game, it inspects the match's true configured cap table at:
  `pPlayer + 0x4AC + (PlayerID * 0x28)`
* When toggled OFF, it restores the match's exact scenario-defined population limit.

---

## Memory Map Reference (Zen Edition v1.59.1)

All addresses are relative to `Battle_Realms_F.exe` base address (ASLR dynamic base):

| Data Structure / Pointer | Address / Offset | Details |
| :--- | :--- | :--- |
| **Local Player Pointer** | `Base + 0x513228` | Local human player controller object |
| **Current / Max Rice** | `pPlayer + 0xD4` / `+0xDC` | 32-bit signed integers |
| **Current / Max Water** | `pPlayer + 0xD8` / `+0xE0` | 32-bit signed integers |
| **Yin / Yang Points** | `pPlayer + 0x2E4` / `+0x2E8` | 32-bit signed integers |
| **Player ID** | `pPlayer + 0x6C` | 0 = Player 1, 1 = Player 2, etc. |
| **Scenario Configured Cap Table** | `pPlayer + 0x4AC + (ID * 0x28)` | Original match population limit |
| **Live Population Cap Table** | `Base + 0x539728 + (ID * 4)` | Active population limit table in `.data` |
| **Selected Building Pointer** | `Base + 0x554AC0` | Currently selected building entity |
| **Building Array Pointer** | `Base + 0x553568` | Stride `0x6A4`, 500 max entity slots |
| **Building Tag** | `bldg + 0x6A0` | `0x68` for valid building structures |
| **Building Type Definition** | `bldg + 0x258` | Points to archetype (`+0x04` name, `+0x2C` max HP) |
| **Building Timers** | `bldg + 0x490` / `+0x4B4` | Training and spawn progress counters |
| **Warlock Tower Sub-Timer** | `[bldg + 0x4C0] + 0x14` | Duel / training timer sub-object |
| **Disable / Enable Fog of War** | `Base + 0xDA029` / `+0xDA01C` | Engine functions invoked via remote thread |

---

## Historical Offset Comparison (v1.02 vs. v1.59.1)

| Key | Feature | Original 2001 (v1.02) | Zen Edition (v1.59.1) |
| :---: | :--- | :--- | :--- |
| **F1** | Fill resources | `p=[0x668570]`; `(p+0xD4)->(p+0xCC)` | `p=[Base+0x513228]`; `(p+0xDC)->(p+0xD4)` |
| **F2** | Create peasant | `0x5280 -> [0x646C00]+0x0` | `0x00FFFFFF -> [PlayerHuts+0x490]` |
| **F3** | Reveal map | `1 -> 0x667CCC` | Remote call `Base+0xDA029` (DisableFog) |
| **F4** | Build/Heal bldg | `0x3BC0000 -> [0x6684F0]+0x8C` | `maxHp<<16 -> [PlayerBldgs+0x8C]`, `+0x90=0x10000` |
| **F5** | Instant train | `0xFFFFFF -> [0x677338]+0x4B4` | `0x3FFFFFFF -> [PlayerBldgs+0x490/4B4/4BC]` |
| **F6** | +10 Yin | `10 -> [0x668570]+0x2DC` | `+10 -> [Base+0x513228]+0x2E4` |
| **F7** | +10 Yang | `10 -> [0x668570]+0x2E0` | `+10 -> [Base+0x513228]+0x2E8` |
| **F8** | Unit limit 500 | `0x1F4 -> 0x646C98` | `500 -> [Base+0x539728 + 4*PlayerID]` |

---

## Project Structure

```text
Trainer/
â”œâ”€â”€ BRTrainer/               # C# .NET 9.0 source project
â”‚   â”œâ”€â”€ Program.cs          # Main trainer engine & memory logic
â”‚   â””â”€â”€ BRTrainer.csproj    # Project configuration
â”œâ”€â”€ scratch/                # Research scripts & live memory diagnostics (PowerShell)
â”œâ”€â”€ README.md               # Project documentation & memory reference
â”œâ”€â”€ BRTrainer.exe           # Development build (untrimmed, 70.9 MB)
â””â”€â”€ ZenTrainer1.59.1.exe    # Community standalone release (trimmed & compressed, 10.9 MB)
```

---

## Build Instructions

### Prerequisites
* [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)

### 1. Build Development Executable (`BRTrainer.exe` ~70 MB)
```bash
dotnet publish BRTrainer/BRTrainer.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o .
```

### 2. Build Community Standalone Executable (`ZenTrainer1.59.1.exe` ~10 MB)
```bash
dotnet publish BRTrainer/BRTrainer.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:EnableCompressionInSingleFile=true -o ./dist
```
Rename the resulting binary to `ZenTrainer1.59.1.exe`.

---

## Notes & Limitations
* **Single Player Only**: Battle Realms utilizes a deterministic lockstep peer-to-peer network model. Modifying local memory in multiplayer causes an immediate simulation checksum divergence (**Out of Sync / OOS error**), disconnecting the match.
