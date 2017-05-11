-- This is an automatically generated Lua API definition generated for release-20160508 of OpenRA.
-- https://github.com/OpenRA/OpenRA/wiki/Utility was used with the --zbstudio-lua-api parameter.
-- See https://github.com/OpenRA/OpenRA/wiki/Lua-API for human readable documentation.

return {
  Actor = {
    type = "class",
    childs = {
      BuildTime = {
        type = "function",
        description = [[Returns the build time (in ticks) of the requested unit type.]],
        args = "(string type)",
        returns = "(int)",
      },
      Create = {
        type = "function",
        description = [[Create a new actor. initTable specifies a list of key-value pairs that defines the initial parameters for the actor's traits.]],
        args = "(string type, bool addToWorld, LuaTable initTable)",
        returns = "(Actor)",
      },
      CruiseAltitude = {
        type = "function",
        description = [[Returns the cruise altitude of the requested unit type (zero if it is ground-based).]],
        args = "(string type)",
        returns = "(int)",
      },
    }
  },
  Beacon = {
    type = "class",
    childs = {
      New = {
        type = "function",
        description = [[Creates a new beacon that stays for the specified time at the specified WPos. Does not remove player set beacons, nor gets removed by placing them.]],
        args = "(Player owner, WPos position, int duration = 750, bool showRadarPings = True, string palettePrefix = player)",
        returns = "(Beacon)",
      },
    }
  },
  Camera = {
    type = "class",
    childs = {
      Position = {
        type = "value",
        description = [[The center of the visible viewport.]],
      },
    }
  },
  CPos = {
    type = "class",
    childs = {
      New = {
        type = "function",
        description = [[Create a new CPos with the specified coordinates.]],
        args = "(int x, int y)",
        returns = "(CPos)",
      },
      Zero = {
        type = "value",
        description = [[The cell coordinate origin.]],
      },
    }
  },
  CVec = {
    type = "class",
    childs = {
      New = {
        type = "function",
        description = [[Create a new CVec with the specified coordinates.]],
        args = "(int x, int y)",
        returns = "(CVec)",
      },
      Zero = {
        type = "value",
        description = [[The cell zero-vector.]],
      },
    }
  },
  DateTime = {
    type = "class",
    childs = {
      GameTime = {
        type = "value",
        description = [[Get the current game time (in ticks).]],
      },
      IsHalloween = {
        type = "value",
        description = [[True on the 31st of October.]],
      },
      Minutes = {
        type = "function",
        description = [[Converts the number of minutes into game time (ticks).]],
        args = "(int minutes)",
        returns = "(int)",
      },
      Seconds = {
        type = "function",
        description = [[Converts the number of seconds into game time (ticks).]],
        args = "(int seconds)",
        returns = "(int)",
      },
    }
  },
  Facing = {
    type = "class",
    childs = {
      East = {
        type = "value",
      },
      North = {
        type = "value",
      },
      NorthEast = {
        type = "value",
      },
      NorthWest = {
        type = "value",
      },
      South = {
        type = "value",
      },
      SouthEast = {
        type = "value",
      },
      SouthWest = {
        type = "value",
      },
      West = {
        type = "value",
      },
    }
  },
  HSLColor = {
    type = "class",
    childs = {
      Aqua = {
        type = "value",
      },
      Black = {
        type = "value",
      },
      Blue = {
        type = "value",
      },
      Brown = {
        type = "value",
      },
      Cyan = {
        type = "value",
      },
      DarkBlue = {
        type = "value",
      },
      DarkCyan = {
        type = "value",
      },
      DarkGray = {
        type = "value",
      },
      DarkGreen = {
        type = "value",
      },
      DarkOrange = {
        type = "value",
      },
      DarkRed = {
        type = "value",
      },
      FromHex = {
        type = "function",
        description = [[Create a new HSL color with the specified red/green/blue/[alpha] hex string (rrggbb[aa]).]],
        args = "(string value)",
        returns = "(HSLColor)",
      },
      FromRGB = {
        type = "function",
        description = [[Create a new HSL color with the specified red/green/blue/[alpha] values.]],
        args = "(int red, int green, int blue, int alpha = 255)",
        returns = "(HSLColor)",
      },
      Fuchsia = {
        type = "value",
      },
      Gold = {
        type = "value",
      },
      Gray = {
        type = "value",
      },
      Green = {
        type = "value",
      },
      LawnGreen = {
        type = "value",
      },
      LightBlue = {
        type = "value",
      },
      LightCyan = {
        type = "value",
      },
      LightGray = {
        type = "value",
      },
      LightGreen = {
        type = "value",
      },
      LightYellow = {
        type = "value",
      },
      Lime = {
        type = "value",
      },
      LimeGreen = {
        type = "value",
      },
      Magenta = {
        type = "value",
      },
      Maroon = {
        type = "value",
      },
      Navy = {
        type = "value",
      },
      New = {
        type = "function",
        description = [[Create a new HSL color with the specified hue/saturation/luminosity.]],
        args = "(int hue, int saturation, int luminosity)",
        returns = "(HSLColor)",
      },
      Olive = {
        type = "value",
      },
      Orange = {
        type = "value",
      },
      OrangeRed = {
        type = "value",
      },
      Purple = {
        type = "value",
      },
      Red = {
        type = "value",
      },
      Salmon = {
        type = "value",
      },
      SkyBlue = {
        type = "value",
      },
      Teal = {
        type = "value",
      },
      White = {
        type = "value",
      },
      Yellow = {
        type = "value",
      },
    }
  },
  Lighting = {
    type = "class",
    childs = {
      Ambient = {
        type = "value",
      },
      Blue = {
        type = "value",
      },
      Flash = {
        type = "function",
        description = [[Controls the `FlashPaletteEffect` trait.]],
        args = "(string type = nil, int ticks = -1)",
        returns = "(void)",
      },
      Green = {
        type = "value",
      },
      Red = {
        type = "value",
      },
    }
  },
  Map = {
    type = "class",
    childs = {
      ActorsInBox = {
        type = "function",
        description = [[Returns a table of all actors within the requested rectangle, filtered using the specified function.]],
        args = "(WPos topLeft, WPos bottomRight, LuaFunction filter = nil)",
        returns = "(Actor[])",
      },
      ActorsInCircle = {
        type = "function",
        description = [[Returns a table of all actors within the requested region, filtered using the specified function.]],
        args = "(WPos location, WDist radius, LuaFunction filter = nil)",
        returns = "(Actor[])",
      },
      ActorsWithTag = {
        type = "function",
        description = [[Returns a table of all actors tagged with the given string.]],
        args = "(string tag)",
        returns = "(Actor[])",
      },
      BottomRight = {
        type = "value",
        description = [[Returns the location of the bottom-right corner of the map (assuming zero terrain height).]],
      },
      CenterOfCell = {
        type = "function",
        description = [[Returns the center of a cell in world coordinates.]],
        args = "(CPos cell)",
        returns = "(WPos)",
      },
      ClosestEdgeCell = {
        type = "function",
        description = [[Returns the closest cell on the visible border of the map from the given cell.]],
        args = "(CPos givenCell)",
        returns = "(CPos)",
      },
      ClosestMatchingEdgeCell = {
        type = "function",
        description = [[Returns the first cell on the visible border of the map from the given cell,
matching the filter function called as function(CPos cell).]],
        args = "(CPos givenCell, LuaFunction filter)",
        returns = "(CPos)",
      },
      Difficulty = {
        type = "value",
        description = [[Returns the difficulty selected by the player before starting the mission.]],
      },
      IsNamedActor = {
        type = "function",
        description = [[Returns true if actor was originally specified in the map file.]],
        args = "(Actor actor)",
        returns = "(bool)",
      },
      IsSinglePlayer = {
        type = "value",
        description = [[Returns true if there is only one human player.]],
      },
      NamedActor = {
        type = "function",
        description = [[Returns the actor that was specified with a given name in the map file (or nil, if the actor is dead or not found).]],
        args = "(string actorName)",
        returns = "(Actor)",
      },
      NamedActors = {
        type = "value",
        description = [[Returns a table of all the actors that were specified in the map file.]],
      },
      RandomCell = {
        type = "function",
        description = [[Returns a random cell inside the visible region of the map.]],
        args = "()",
        returns = "(CPos)",
      },
      RandomEdgeCell = {
        type = "function",
        description = [[Returns a random cell on the visible border of the map.]],
        args = "()",
        returns = "(CPos)",
      },
      TopLeft = {
        type = "value",
        description = [[Returns the location of the top-left corner of the map (assuming zero terrain height).]],
      },
    }
  },
  Media = {
    type = "class",
    childs = {
      Debug = {
        type = "function",
        description = [[Displays a debug message to the player, if "Show Map Debug Messages" is checked in the settings.]],
        args = "(string text)",
        returns = "(void)",
      },
      DisplayMessage = {
        type = "function",
        description = [[Display a text message to the player.]],
        args = "(string text, string prefix = Mission, Nullable`1 color = nil)",
        returns = "(void)",
      },
      FloatingText = {
        type = "function",
        description = [[Display a text message at the specified location.]],
        args = "(string text, WPos position, int duration = 30, Nullable`1 color = nil)",
        returns = "(void)",
      },
      PlayMovieFullscreen = {
        type = "function",
        description = [[Play a VQA video fullscreen. File name has to include the file extension.]],
        args = "(string movie, LuaFunction func = nil)",
        returns = "(void)",
      },
      PlayMovieInRadar = {
        type = "function",
        description = [[Play a VQA video in the radar window. File name has to include the file extension. Returns true on success, if the movie wasn't found the function returns false and the callback is executed.]],
        args = "(string movie, LuaFunction playComplete = nil)",
        returns = "(bool)",
      },
      PlayMusic = {
        type = "function",
        description = [[Play track defined in music.yaml or map.yaml, or keep track empty for playing a random song.]],
        args = "(string track = nil, LuaFunction func = nil)",
        returns = "(void)",
      },
      PlaySound = {
        type = "function",
        description = [[Play a sound file]],
        args = "(string file)",
        returns = "(void)",
      },
      PlaySoundNotification = {
        type = "function",
        description = [[Play a sound listed in notifications.yaml]],
        args = "(Player player, string notification)",
        returns = "(void)",
      },
      PlaySpeechNotification = {
        type = "function",
        description = [[Play an announcer voice listed in notifications.yaml]],
        args = "(Player player, string notification)",
        returns = "(void)",
      },
      SetBackgroundMusic = {
        type = "function",
        description = [[Play track defined in music.yaml or map.yaml as background music. If music is already playing use Media.StopMusic() to stop it and the background music will start automatically. Keep the track empty to disable background music.]],
        args = "(string track = nil)",
        returns = "(void)",
      },
      StopMusic = {
        type = "function",
        description = [[Stop the current song.]],
        args = "()",
        returns = "(void)",
      },
    }
  },
  Player = {
    type = "class",
    childs = {
      GetPlayer = {
        type = "function",
        description = [[Returns the player with the specified internal name, or nil if a match is not found.]],
        args = "(string name)",
        returns = "(Player)",
      },
      GetPlayers = {
        type = "function",
        description = [[Returns a table of players filtered by the specified function.]],
        args = "(LuaFunction filter)",
        returns = "(Player[])",
      },
    }
  },
  Reinforcements = {
    type = "class",
    childs = {
      Reinforce = {
        type = "function",
        description = [[Send reinforcements consisting of multiple units. Supports ground-based, naval and air units. The first member of the entryPath array will be the units' spawnpoint, while the last one will be their destination. If actionFunc is given, it will be executed once a unit has reached its destination. actionFunc will be called as actionFunc(Actor actor)]],
        args = "(Player owner, String[] actorTypes, CPos[] entryPath, int interval = 25, LuaFunction actionFunc = nil)",
        returns = "(Actor[])",
      },
      ReinforceWithTransport = {
        type = "function",
        description = [[Send reinforcements in a transport. A transport can be a ground unit (APC etc.), ships and aircraft. The first member of the entryPath array will be the spawnpoint for the transport, while the last one will be its destination. The last member of the exitPath array is be the place where the transport will be removed from the game. When the transport has reached the destination, it will unload its cargo unless a custom actionFunc has been supplied. Afterwards, the transport will follow the exitPath and leave the map, unless a custom exitFunc has been supplied. actionFunc will be called as actionFunc(Actor transport, Actor[] cargo). exitFunc will be called as exitFunc(Actor transport).]],
        args = "(Player owner, string actorType, String[] cargoTypes, CPos[] entryPath, CPos[] exitPath = nil, LuaFunction actionFunc = nil, LuaFunction exitFunc = nil)",
        returns = "(LuaTable)",
      },
    }
  },
  Trigger = {
    type = "class",
    childs = {
      AfterDelay = {
        type = "function",
        description = [[Call a function after a specified delay. The callback function will be called as func().]],
        args = "(int delay, LuaFunction func)",
        returns = "(void)",
      },
      Clear = {
        type = "function",
        description = [[Removes the specified trigger from this actor. Note that the removal will only take effect at the end of a tick, so you must not add new triggers at the same time that you are calling this function.]],
        args = "(Actor a, string triggerName)",
        returns = "(void)",
      },
      ClearAll = {
        type = "function",
        description = [[Removes all triggers from this actor. Note that the removal will only take effect at the end of a tick, so you must not add new triggers at the same time that you are calling this function.]],
        args = "(Actor a)",
        returns = "(void)",
      },
      OnAddedToWorld = {
        type = "function",
        description = [[Call a function when this actor is added to the world. The callback function will be called as func(Actor self).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnAllKilled = {
        type = "function",
        description = [[Call a function when all of the actors in a group are killed. The callback function will be called as func().]],
        args = "(Actor[] actors, LuaFunction func)",
        returns = "(void)",
      },
      OnAllKilledOrCaptured = {
        type = "function",
        description = [[Call a function when all of the actors in a group have been killed or captured. The callback function will be called as func().]],
        args = "(Actor[] actors, LuaFunction func)",
        returns = "(void)",
      },
      OnAllRemovedFromWorld = {
        type = "function",
        description = [[Call a function when all of the actors in a group have been removed from the world. The callback function will be called as func().]],
        args = "(Actor[] actors, LuaFunction func)",
        returns = "(void)",
      },
      OnAnyKilled = {
        type = "function",
        description = [[Call a function when one of the actors in a group is killed. The callback function will be called as func(Actor killed).]],
        args = "(Actor[] actors, LuaFunction func)",
        returns = "(void)",
      },
      OnCapture = {
        type = "function",
        description = [[Call a function when this actor is captured. The callback function will be called as func(Actor self, Actor captor, Player oldOwner, Player newOwner).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnDamaged = {
        type = "function",
        description = [[Call a function when the actor is damaged. The callback function will be called as func(Actor self, Actor attacker).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnDiscovered = {
        type = "function",
        description = [[Call a function when this actor is discovered by an enemy or a player with a Neutral stance. The callback function will be called as func(Actor discovered, Player discoverer).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnEnteredFootprint = {
        type = "function",
        description = [[Call a function when a ground-based actor enters this cell footprint. Returns the trigger id for later removal using RemoveFootprintTrigger(int id). The callback function will be called as func(Actor a, int id).]],
        args = "(CPos[] cells, LuaFunction func)",
        returns = "(int)",
      },
      OnEnteredProximityTrigger = {
        type = "function",
        description = [[Call a function when an actor enters this range. Returns the trigger id for later removal using RemoveProximityTrigger(int id). The callback function will be called as func(Actor a, int id).]],
        args = "(WPos pos, WDist range, LuaFunction func)",
        returns = "(int)",
      },
      OnExitedFootprint = {
        type = "function",
        description = [[Call a function when a ground-based actor leaves this cell footprint. Returns the trigger id for later removal using RemoveFootprintTrigger(int id). The callback function will be called as func(Actor a, int id).]],
        args = "(CPos[] cells, LuaFunction func)",
        returns = "(int)",
      },
      OnExitedProximityTrigger = {
        type = "function",
        description = [[Call a function when an actor leaves this range. Returns the trigger id for later removal using RemoveProximityTrigger(int id). The callback function will be called as func(Actor a, int id).]],
        args = "(WPos pos, WDist range, LuaFunction func)",
        returns = "(int)",
      },
      OnIdle = {
        type = "function",
        description = [[Call a function each tick that the actor is idle. The callback function will be called as func(Actor self).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnInfiltrated = {
        type = "function",
        description = [[Call a function when this actor is infiltrated. The callback function will be called as func(Actor self, Actor infiltrator).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnKilled = {
        type = "function",
        description = [[Call a function when the actor is killed. The callback function will be called as func(Actor self, Actor killer).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnKilledOrCaptured = {
        type = "function",
        description = [[Call a function when this actor is killed or captured. The callback function will be called as func().]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnObjectiveAdded = {
        type = "function",
        description = [[Call a function when this player is assigned a new objective. The callback function will be called as func(Player player, int objectiveID).]],
        args = "(Player player, LuaFunction func)",
        returns = "(void)",
      },
      OnObjectiveCompleted = {
        type = "function",
        description = [[Call a function when this player completes an objective. The callback function will be called as func(Player player, int objectiveID).]],
        args = "(Player player, LuaFunction func)",
        returns = "(void)",
      },
      OnObjectiveFailed = {
        type = "function",
        description = [[Call a function when this player fails an objective. The callback function will be called as func(Player player, int objectiveID).]],
        args = "(Player player, LuaFunction func)",
        returns = "(void)",
      },
      OnPassengerEntered = {
        type = "function",
        description = [[Call a function for each passenger when it enters a transport. The callback function will be called as func(Actor transport, Actor passenger).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnPassengerExited = {
        type = "function",
        description = [[Call a function for each passenger when it exits a transport. The callback function will be called as func(Actor transport, Actor passenger).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnPlayerDiscovered = {
        type = "function",
        description = [[Call a function when this player is discovered by an enemy or neutral player. The callback function will be called as func(Player discovered, Player discoverer, Actor discoveredActor).]],
        args = "(Player discovered, LuaFunction func)",
        returns = "(void)",
      },
      OnPlayerLost = {
        type = "function",
        description = [[Call a function when this player fails any primary objective. The callback function will be called as func(Player player).]],
        args = "(Player player, LuaFunction func)",
        returns = "(void)",
      },
      OnPlayerWon = {
        type = "function",
        description = [[Call a function when this player completes all primary objectives. The callback function will be called as func(Player player).]],
        args = "(Player player, LuaFunction func)",
        returns = "(void)",
      },
      OnProduction = {
        type = "function",
        description = [[Call a function when this actor produces another actor. The callback function will be called as func(Actor producer, Actor produced).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      OnRemovedFromWorld = {
        type = "function",
        description = [[Call a function when this actor is removed from the world. The callback function will be called as func(Actor self).]],
        args = "(Actor a, LuaFunction func)",
        returns = "(void)",
      },
      RemoveFootprintTrigger = {
        type = "function",
        description = [[Removes a previously created footprint trigger.]],
        args = "(int id)",
        returns = "(void)",
      },
      RemoveProximityTrigger = {
        type = "function",
        description = [[Removes a previously created proximity trigger.]],
        args = "(int id)",
        returns = "(void)",
      },
    }
  },
  UserInterface = {
    type = "class",
    childs = {
      SetMissionText = {
        type = "function",
        description = [[Displays a text message at the top center of the screen.]],
        args = "(string text, Nullable`1 color = nil)",
        returns = "(void)",
      },
    }
  },
  Utils = {
    type = "class",
    childs = {
      All = {
        type = "function",
        description = [[Returns true if func returns true for all elements in a collection.]],
        args = "(LuaValue[] collection, LuaFunction func)",
        returns = "(bool)",
      },
      Any = {
        type = "function",
        description = [[Returns true if func returns true for any element in a collection.]],
        args = "(LuaValue[] collection, LuaFunction func)",
        returns = "(bool)",
      },
      Do = {
        type = "function",
        description = [[Calls a function on every element in a collection.]],
        args = "(LuaValue[] collection, LuaFunction func)",
        returns = "(void)",
      },
      ExpandFootprint = {
        type = "function",
        description = [[Expands the given footprint one step along the coordinate axes, and (if requested) diagonals.]],
        args = "(CPos[] footprint, bool allowDiagonal)",
        returns = "(CPos[])",
      },
      FormatTime = {
        type = "function",
        description = [[Returns the ticks formatted to HH:MM:SS.]],
        args = "(int ticks, bool leadingMinuteZero = True)",
        returns = "(string)",
      },
      Random = {
        type = "function",
        description = [[Returns a random value from a collection.]],
        args = "(LuaValue[] collection)",
        returns = "(LuaValue)",
      },
      RandomInteger = {
        type = "function",
        description = [[Returns a random integer x in the range low &lt;= x &lt; high.]],
        args = "(int low, int high)",
        returns = "(int)",
      },
      Skip = {
        type = "function",
        description = [[Skips over the first numElements members of a table and return the rest.]],
        args = "(LuaTable table, int numElements)",
        returns = "(LuaTable)",
      },
      Take = {
        type = "function",
        description = [[Returns the first n values from a collection.]],
        args = "(int n, LuaValue[] source)",
        returns = "(LuaValue[])",
      },
    }
  },
  WDist = {
    type = "class",
    childs = {
      FromCells = {
        type = "function",
        description = [[Create a new WDist by cell distance.]],
        args = "(int numCells)",
        returns = "(WDist)",
      },
      New = {
        type = "function",
        description = [[Create a new WDist.]],
        args = "(int r)",
        returns = "(WDist)",
      },
    }
  },
  WPos = {
    type = "class",
    childs = {
      New = {
        type = "function",
        description = [[Create a new WPos with the specified coordinates.]],
        args = "(int x, int y, int z)",
        returns = "(WPos)",
      },
      Zero = {
        type = "value",
        description = [[The world coordinate origin.]],
      },
    }
  },
  WRange = {
    type = "class",
    childs = {
      FromCells = {
        type = "function",
        description = [[Create a new WRange by cell distance. DEPRECATED! Will be removed.]],
        args = "(int numCells)",
        returns = "(WDist)",
      },
      New = {
        type = "function",
        description = [[Create a new WRange. DEPRECATED! Will be removed.]],
        args = "(int r)",
        returns = "(WDist)",
      },
    }
  },
  WVec = {
    type = "class",
    childs = {
      New = {
        type = "function",
        description = [[Create a new WVec with the specified coordinates.]],
        args = "(int x, int y, int z)",
        returns = "(WVec)",
      },
      Zero = {
        type = "value",
        description = [[The world zero-vector.]],
      },
    }
  },
  AcceptsUpgrade = {
    type = "function",
        description = [[Check whether this actor accepts a specific upgrade.]],
    args = "(string upgrade)",
    returns = "(bool)",
  },
  AddPrimaryObjective = {
    type = "function",
        description = [[Add a primary mission objective for this player. The function returns the ID of the newly created objective, so that it can be referred to later.]],
    args = "(string description)",
    returns = "(int)",
  },
  AddSecondaryObjective = {
    type = "function",
        description = [[Add a secondary mission objective for this player. The function returns the ID of the newly created objective, so that it can be referred to later.]],
    args = "(string description)",
    returns = "(int)",
  },
  AddTag = {
    type = "function",
        description = [[Add a tag to the actor. Returns true on success, false otherwise (for example the actor may already have the given tag).]],
    args = "(string tag)",
    returns = "(bool)",
  },
  Attack = {
    type = "function",
        description = [[Attack the target actor. The target actor needs to be visible.]],
    args = "(Actor targetActor, bool allowMove = True, bool forceAttack = False)",
    returns = "(void)",
  },
  AttackMove = {
    type = "function",
        description = [[Move to a cell, but stop and attack anything within range on the way. closeEnough defines an optional range (in cells) that will be considered close enough to complete the activity.]],
    args = "(CPos cell, int closeEnough = 0)",
    returns = "(void)",
  },
  Build = {
    type = "function",
        description = [[Build the specified set of actors using a TD-style (per building) production queue. The function will return true if production could be started, false otherwise. If an actionFunc is given, it will be called as actionFunc(Actor[] actors) once production of all actors has been completed.  The actors array is guaranteed to only contain alive actors.]],
    args = "(String[] actorTypes, LuaFunction actionFunc = nil)",
    returns = "(bool)",
  },
  Build = {
    type = "function",
        description = [[Build the specified set of actors using classic (RA-style) production queues. The function will return true if production could be started, false otherwise. If an actionFunc is given, it will be called as actionFunc(Actor[] actors) once production of all actors has been completed. The actors array is guaranteed to only contain alive actors. Note: This function will fail to work when called during the first tick.]],
    args = "(String[] actorTypes, LuaFunction actionFunc = nil)",
    returns = "(bool)",
  },
  CallFunc = {
    type = "function",
        description = [[Run an arbitrary Lua function.]],
    args = "(LuaFunction func)",
    returns = "(void)",
  },
  Capture = {
    type = "function",
        description = [[Captures the target actor.]],
    args = "(Actor target)",
    returns = "(void)",
  },
  Cash = {
    type = "value",
        description = [[The amount of cash held by the player.]],
  },
  CenterPosition = {
    type = "value",
        description = [[The actor position in world coordinates.]],
  },
  Chronoshift = {
    type = "function",
        description = [[Chronoshift a group of actors. A duration of 0 will teleport the actors permanently.]],
    args = "(LuaTable unitLocationPairs, int duration = 0, bool killCargo = False)",
    returns = "(void)",
  },
  Color = {
    type = "value",
        description = [[The player's color.]],
  },
  Demolish = {
    type = "function",
        description = [[Demolish the target actor.]],
    args = "(Actor target)",
    returns = "(void)",
  },
  Deploy = {
    type = "function",
        description = [[Queue a new transformation.]],
    args = "()",
    returns = "(void)",
  },
  Destroy = {
    type = "function",
        description = [[Remove the actor from the game, without triggering any death notification.]],
    args = "()",
    returns = "(void)",
  },
  DisguiseAs = {
    type = "function",
        description = [[Disguises as the target actor.]],
    args = "(Actor target)",
    returns = "(void)",
  },
  DisguiseAsType = {
    type = "function",
        description = [[Disguises as the target type with the specified owner.]],
    args = "(string actorType, Player newOwner)",
    returns = "(void)",
  },
  EnterTransport = {
    type = "function",
        description = [[Move to and enter the transport.]],
    args = "(Actor transport)",
    returns = "(void)",
  },
  Facing = {
    type = "value",
        description = [[The direction that the actor is facing.]],
  },
  Faction = {
    type = "value",
        description = [[The player's faction.]],
  },
  FindResources = {
    type = "function",
        description = [[Search for nearby resources and begin harvesting.]],
    args = "()",
    returns = "(void)",
  },
  GetActorsByType = {
    type = "function",
        description = [[Returns all living actors of the specified type of this player.]],
    args = "(string type)",
    returns = "(Actor[])",
  },
  GetGroundAttackers = {
    type = "function",
        description = [[Returns an array of actors representing all ground attack units of this player.]],
    args = "()",
    returns = "(Actor[])",
  },
  GetObjectiveDescription = {
    type = "function",
        description = [[Returns the description of an objective.]],
    args = "(int id)",
    returns = "(string)",
  },
  GetObjectiveType = {
    type = "function",
        description = [[Returns the type of an objective.]],
    args = "(int id)",
    returns = "(string)",
  },
  GrantTimedUpgrade = {
    type = "function",
        description = [[Grant a limited-time upgrade to this actor.]],
    args = "(string upgrade, int duration)",
    returns = "(void)",
  },
  GrantUpgrade = {
    type = "function",
        description = [[Grant an upgrade to this actor.]],
    args = "(string upgrade)",
    returns = "(void)",
  },
  Guard = {
    type = "function",
        description = [[Guard the target actor.]],
    args = "(Actor targetActor)",
    returns = "(void)",
  },
  HasNoRequiredUnits = {
    type = "function",
        description = [[Returns true if this player has lost all units/actors that have the MustBeDestroyed trait (according to the short game option).]],
    args = "()",
    returns = "(bool)",
  },
  HasPassengers = {
    type = "value",
        description = [[Specifies whether transport has any passengers.]],
  },
  HasPrerequisites = {
    type = "function",
        description = [[Check if the player has these prerequisites available.]],
    args = "(String[] type)",
    returns = "(bool)",
  },
  HasProperty = {
    type = "function",
        description = [[Test whether an actor has a specific property.]],
    args = "(string name)",
    returns = "(bool)",
  },
  HasTag = {
    type = "function",
        description = [[Specifies whether or not the actor has a particular tag.]],
    args = "(string tag)",
    returns = "(bool)",
  },
  Health = {
    type = "value",
        description = [[Current health of the actor.]],
  },
  Hunt = {
    type = "function",
        description = [[Seek out and attack nearby targets.]],
    args = "()",
    returns = "(void)",
  },
  Infiltrate = {
    type = "function",
        description = [[Infiltrate the target actor.]],
    args = "(Actor target)",
    returns = "(void)",
  },
  InternalName = {
    type = "value",
        description = [[The player's internal name.]],
  },
  IsAlliedWith = {
    type = "function",
        description = [[Returns true if the player is allied with the other player.]],
    args = "(Player targetPlayer)",
    returns = "(bool)",
  },
  IsBot = {
    type = "value",
        description = [[Returns true if the player is a bot.]],
  },
  IsDead = {
    type = "value",
        description = [[Specifies whether the actor is alive or dead.]],
  },
  IsIdle = {
    type = "value",
        description = [[Specifies whether the actor is idle (not performing any activities).]],
  },
  IsInWorld = {
    type = "value",
        description = [[Specifies whether the actor is in the world.]],
  },
  IsLocalPlayer = {
    type = "value",
        description = [[Returns true if the player is the local player.]],
  },
  IsMobile = {
    type = "value",
        description = [[Whether the actor can move (false if immobilized).]],
  },
  IsNonCombatant = {
    type = "value",
        description = [[Returns true if the player is non combatant.]],
  },
  IsObjectiveCompleted = {
    type = "function",
        description = [[Returns true if the objective has been successfully completed, false otherwise.]],
    args = "(int id)",
    returns = "(bool)",
  },
  IsObjectiveFailed = {
    type = "function",
        description = [[Returns true if the objective has been failed, false otherwise.]],
    args = "(int id)",
    returns = "(bool)",
  },
  IsPrimaryBuilding = {
    type = "value",
        description = [[Query or set the factory's primary building status.]],
  },
  IsProducing = {
    type = "function",
        description = [[Check whether the factory's production queue that builds this type of actor is currently busy. Note: it does not check whether this particular type of actor is being produced.]],
    args = "(string actorType)",
    returns = "(bool)",
  },
  IsProducing = {
    type = "function",
        description = [[Check whether the production queue that builds this type of actor is currently busy. Note: it does not check whether this particular type of actor is being produced.]],
    args = "(string actorType)",
    returns = "(bool)",
  },
  IsTaggable = {
    type = "value",
        description = [[Specifies whether or not the actor supports 'tags'.]],
  },
  Kill = {
    type = "function",
        description = [[Kill the actor.]],
    args = "()",
    returns = "(void)",
  },
  LoadPassenger = {
    type = "function",
        description = [[Teleport an existing actor inside this transport.]],
    args = "(Actor a)",
    returns = "(void)",
  },
  Location = {
    type = "value",
        description = [[The actor position in cell coordinates.]],
  },
  MarkCompletedObjective = {
    type = "function",
        description = [[Mark an objective as completed.  This needs the objective ID returned by AddObjective as argument.  When this player has completed all primary objectives, (s)he has won the game.]],
    args = "(int id)",
    returns = "(void)",
  },
  MarkFailedObjective = {
    type = "function",
        description = [[Mark an objective as failed.  This needs the objective ID returned by AddObjective as argument.  Secondary objectives do not have any influence whatsoever on the outcome of the game.]],
    args = "(int id)",
    returns = "(void)",
  },
  MaxHealth = {
    type = "value",
        description = [[Maximum health of the actor.]],
  },
  Move = {
    type = "function",
        description = [[Moves within the cell grid. closeEnough defines an optional range (in cells) that will be considered close enough to complete the activity.]],
    args = "(CPos cell, int closeEnough = 0)",
    returns = "(void)",
  },
  Move = {
    type = "function",
        description = [[Fly within the cell grid.]],
    args = "(CPos cell)",
    returns = "(void)",
  },
  MoveIntoWorld = {
    type = "function",
        description = [[Moves from outside the world into the cell grid.]],
    args = "(CPos cell)",
    returns = "(void)",
  },
  Name = {
    type = "value",
        description = [[The player's name.]],
  },
  Owner = {
    type = "value",
        description = [[The player that owns the actor.]],
  },
  Paradrop = {
    type = "function",
        description = [[Command transport to paradrop passengers near the target cell.]],
    args = "(CPos cell)",
    returns = "(void)",
  },
  Patrol = {
    type = "function",
        description = [[Patrol along a set of given waypoints. The action is repeated by default, and the actor will wait for `wait` ticks at each waypoint.]],
    args = "(CPos[] waypoints, bool loop = True, int wait = 0)",
    returns = "(void)",
  },
  PatrolUntil = {
    type = "function",
        description = [[Patrol along a set of given waypoints until a condition becomes true. The actor will wait for `wait` ticks at each waypoint.]],
    args = "(CPos[] waypoints, LuaFunction func, int wait = 0)",
    returns = "(void)",
  },
  Power = {
    type = "value",
        description = [[Returns the power drained/provided by this actor.]],
  },
  PowerDrained = {
    type = "value",
        description = [[Returns the power used by the player.]],
  },
  PowerProvided = {
    type = "value",
        description = [[Returns the total of the power the player has.]],
  },
  PowerState = {
    type = "value",
        description = [[Returns the player's power state ("Normal", "Low" or "Critical").]],
  },
  Produce = {
    type = "function",
        description = [[Build a unit, ignoring the production queue. The activity will wait if the exit is blocked.]],
    args = "(string actorType, string factionVariant = nil)",
    returns = "(void)",
  },
  Race = {
    type = "value",
        description = [[The player's race. (DEPRECATED! Use the `Faction` property.)]],
  },
  RallyPoint = {
    type = "value",
        description = [[Query or set a factory's rally point.]],
  },
  RemoveTag = {
    type = "function",
        description = [[Remove a tag from the actor. Returns true on success, false otherwise (tag was not present).]],
    args = "(string tag)",
    returns = "(bool)",
  },
  ResourceCapacity = {
    type = "value",
        description = [[The maximum resource storage of the player.]],
  },
  Resources = {
    type = "value",
        description = [[The amount of harvestable resources held by the player.]],
  },
  ReturnToBase = {
    type = "function",
        description = [[Return to the base, which is either the airfield given, or an auto-selected one otherwise.]],
    args = "(Actor airfield = nil)",
    returns = "(void)",
  },
  RevokeUpgrade = {
    type = "function",
        description = [[Revoke an upgrade that was previously granted using GrantUpgrade.]],
    args = "(string upgrade)",
    returns = "(void)",
  },
  Scatter = {
    type = "function",
        description = [[Leave the current position in a random direction.]],
    args = "()",
    returns = "(void)",
  },
  ScriptedMove = {
    type = "function",
        description = [[Moves within the cell grid, ignoring lane biases.]],
    args = "(CPos cell)",
    returns = "(void)",
  },
  SendAirstrike = {
    type = "function",
        description = [[Activate the actor's Airstrike Power.]],
    args = "(WPos target, bool randomize = True, int facing = 0)",
    returns = "(void)",
  },
  SendParatroopers = {
    type = "function",
        description = [[Activate the actor's Paratroopers Power. Returns the dropped units.]],
    args = "(WPos target, bool randomize = True, int facing = 0)",
    returns = "(Actor[])",
  },
  Spawn = {
    type = "value",
        description = [[The player's spawnpoint ID.]],
  },
  Stance = {
    type = "value",
        description = [[Current actor stance. Returns nil if this actor doesn't support stances.]],
  },
  StartBuildingRepairs = {
    type = "function",
        description = [[Start repairs on this building. `repairer` can be an allied player.]],
    args = "(Player repairer = nil)",
    returns = "(void)",
  },
  Stop = {
    type = "function",
        description = [[Attempt to cancel any active activities.]],
    args = "()",
    returns = "(void)",
  },
  StopBuildingRepairs = {
    type = "function",
        description = [[Stop repairs on this building. `repairer` can be an allied player.]],
    args = "(Player repairer = nil)",
    returns = "(void)",
  },
  Team = {
    type = "value",
        description = [[The player's team ID.]],
  },
  Teleport = {
    type = "function",
        description = [[Instantly moves the actor to the specified cell.]],
    args = "(CPos cell)",
    returns = "(void)",
  },
  TriggerPowerOutage = {
    type = "function",
        description = [[Triggers low power for the chosen amount of ticks.]],
    args = "(int ticks)",
    returns = "(void)",
  },
  Type = {
    type = "value",
        description = [[The type of the actor (e.g. "e1").]],
  },
  UnloadPassenger = {
    type = "function",
        description = [[Remove the first actor from the transport.  This actor is not added to the world.]],
    args = "()",
    returns = "(Actor)",
  },
  UnloadPassengers = {
    type = "function",
        description = [[Command transport to unload passengers.]],
    args = "()",
    returns = "(void)",
  },
  Wait = {
    type = "function",
        description = [[Wait for a specified number of game ticks (25 ticks = 1 second).]],
    args = "(int ticks)",
    returns = "(void)",
  },
}
