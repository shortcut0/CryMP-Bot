# CryMP-Bot

hi,

this repo contains the lua and au3 sources for some bot i made for online matches for the first person shooter game 'Crysis'

---------------------------
$${\color{orange}INSTALL:}$$
  - Download CryMP-Client Bot Executable (https://nomad.nullptr.one/~finch/CryMP-Bot64.exe)
  - Download this repository and extract it to "[CRYSIS_DIRECTORY]\CryMP-Bot"
  - Place the Bot Executable inside Bin64 folder or create a shortcut and append "-dir PATH_TO_YOUR_CRYSIS_FOLDER" to the command line
  - DONE!
    
---------------------------

$${\color{red}TODO:}$$
  + Nothing? Fix Bugs?!

---------------------------
$${\color{green}DONE:}$$
  * [13.07.2022] Create the repo
  * [13.07.2022] Upload Includes and Core File
  * [16.07.2022] Upload New Includes and Pathfinding System
  * [17.07.2022] Upload New Navmesh and Improved Pathfinding System
    * Created New Navigation System
    * Updated Navigation System and Navmesh files
    * Imporved Navmesh AutoGen
  * [20.07.2022] Added new required Includes and Updated Pathfinding files
  * [10.07.2024] Cleaned and Uploaded Remaining Files
    * Navigation Data for some maps
  * [10.07.2024] Folder restructure
    * Now 'CryMP-Bot' instead of 'Bot'
    * Gave files their appropriate names
  * [10.07.2024] Complete rewrite of the Bot Core files
    * Rewrote BotMain from Scratch and removed all obsolete, duplicated, and unused functions
    * Moved math related functions to Core\BotMath.lua
    * Moved utility functions to Core\Utilities.lua
    * Created Startup.lua as the first file that gets called during.. startup..
    * Moved all API callbacks to BotAPI.lua
    * Moved CVar registration system & functions to CVars.lua
    * Made a temporary fix for badly placed entities that cause the bot to not to go to the correct places in some PS maps.
      - These entities must be manually entered (by their spawn-name) in EntityData.lua alongside the actual & appropriate position
    * Minor changes to BotAI
    * Minor changes to Bot PowerStruggle AI Module
    * Config.lua is now actually being used again, although, some options there are not yet implemented again.
    * Updated includes to latest versions
    * Updated Navigation System to reduce bugs where the bot would get stuck inside walls
    * Improved PathFinding System
    * Improved A* Caching
    * Fixed & Improved error handling and messages
    * Got rid of the cursed Commandline and VBS script calls!!
    * General improments of the AI
      - The bot now walljumps when it's appropriate or saves time when travelling to a point of interest
      - Better item handling and valuing. Ammo, nearby ammo, and weapons and the target now place a role when selecting the optimal weapon
      - Bot is less likely to get stuck or go for swims.
      - The Bot no longer runs around aimlessly hoping to find targets, but instead uses a state-of-the-art X-Ray Wallhack system to locate unsuspecting victims!
    * Much more but i dont recall it
  * [12.07.2024]
    * Changes to item selection and a temporary fix that prevents the bot from using fists when there are perfectly operational items in its inventory
    * Created Servers.lua
      - Definition source for custom server addresses (and ports)
    * Created server-specific AI modules
      - Located in Core\AI\ServerModules
      - These modules are only executed on specific servers
    * Some minor changes and updates
      - Bot no longer jumps or sprints inside buildings since it caused it to get stuck on corners or miss waypoint nodes
      - Updated Includes
      - Minor changes to Pathfinding
  * [14.07.2024]
    * Minor fixes to item selection handler
      - No longer trying to select and fire items when swimming
      - Fixed a bug where bot would endlessly cycle between perfectly operational items
      - Bot uses RPG on vehicles if appropriate (TODO: target is near vehicle)
    * Unlocked stance switching in C++ to allow bot to unprone all the time (BOT_SIMPLYFIED_STANCES >= { 1, 2 })
      - >0, ignores some checks, >=2, ignores all checks (but sometimes causes character collision to glitch out)
    * Log spam fix
      - When a non-player entitiy was spawned (connected) or removed (disconnected)
    * Fixes to Navigation System
      - Ability to skip nodes if bot somehow already advanced on it's path without ever reaching it's original WP
    * Changes to PathFinding System
      - Bot can now swim and dive and follow underwater waypoints
      - Rewrote some link validation code for better linking
      - Updated Fail handler
      - Fixed a bug where exporting navmesh failed to open the file for writing
  
---------------------------
$${\color{pink}-shortcut0 <3}$$
