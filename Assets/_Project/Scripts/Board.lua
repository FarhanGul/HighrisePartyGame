-- Constants
local TotalLaps = 3

--!SerializeField
local piecesGameObject : GameObject = nil
--!SerializeField
local matchmakerGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil

local tiles = {}
local location
local health
local laps
local matchmaker
local cardManager
local gameIndex
local racers
local teleportTileLocations
local onMoveFinished
local isInitialized = false

-- Events
local e_sendHealthToServer = Event.new("sendHealthToServer")
local e_sendHealthToClient = Event.new("sendHealthToClient")
local e_sendLocationToServer = Event.new("sendLocationToServer")
local e_sendLocationToClient = Event.new("sendLocationToClient")
local e_sendLandedOnSpecialTileToServer = Event.new("sendLandedOnSpecialTileToServer")
local e_sendLandedOnSpecialTileToClient = Event.new("sendLandedOnSpecialTileToClient")

function self:ServerAwake()
    e_sendHealthToServer:Connect(function(player,targetPlayer,id,_health)
        e_sendHealthToClient:FireClient(targetPlayer,id,_health)
    end)
    e_sendLocationToServer:Connect(function(player,targetPlayer,id,_location)
        e_sendLocationToClient:FireClient(targetPlayer,id,_location)
    end)
    e_sendLandedOnSpecialTileToServer:Connect(function(player,targetPlayer,landedPlayer,tileType)
        e_sendLandedOnSpecialTileToClient:FireClient(targetPlayer,landedPlayer,tileType)
    end)
end

function self:ClientAwake()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    cardManager = cardManagerGameObject:GetComponent("CardManager")
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i] = self.transform.GetChild(self.transform,i).gameObject;
    end
    e_sendHealthToClient:Connect(function(_id,_health)
        SetHealth(_id,_health)
    end)
    e_sendLocationToClient:Connect(function(_id,_location)
        SetLocation(_id, _location)
    end)
    e_sendLandedOnSpecialTileToClient:Connect(function(landedPlayer,tileType)
        LandedOnSpecialTile(landedPlayer,tileType)
    end)
end

function SyncedLandedOnSpecialTile(landedPlayer, tileType)
    LandedOnSpecialTile(landedPlayer, tileType)
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendLandedOnSpecialTileToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),landedPlayer,tileType)
    end
end

function LandedOnSpecialTile(landedPlayer,tileType)
    if(landedPlayer ~= nil) then
        HandleTileAudio(tileType)
        if(tileType ~= "Default" and tileType ~= "Start")then
            local label = tileType
            if(label == "Draw3") then label = "Draw 3x" end
            if(label == "Draw2") then label = "Draw 2x" end
            playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
                player = landedPlayer.name,
                text  = "Landed on  "..label,
                help = GetTileHelp(tileType)
            })
        end
    end
end

function SetSyncedLocation(_id,_location)
    SetLocation(_id,_location)
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendLocationToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),_id,_location)
    end
end

function SetLocation(_id,_location)
    location[_id] = _location
    SetPiecePosition(_id)
end

function IsOnSafeTile(_id)
    return tiles[location[_id]]:GetComponent("BoardTile").GetType() == "Dome"
end

function ChangeHealth(_id,_change)
    SetHealth(_id, health[_id]+_change)
end

function SetSyncedHealth(_id,_health)
    SetHealth(_id,_health)
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendHealthToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),_id,health[_id])
    end
end

function SetHealth(_id,_health)
    health[_id] = math.min(4,_health)
    if(_health < health[_id]) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayDamage()
    end
    if(health[_id]  <= 0) then
        matchmaker.GameFinished(gameIndex,racers:GetOtherPlayer(_id))
    end
    playerHudGameObject:GetComponent("RacerUIView").UpdateGameView()
end

function HandleTileAudio(tileType)
    if(tileType == "Teleport") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayTeleport()
    end
    if(tileType == "Mine") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayLaser()
    end
    if(tileType == "Snare") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayLaser()
    end
    if(tileType == "Anomaly") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayAnomaly()
    end
    if(tileType == "Draw" or tileType == "Draw2" or tileType == "Draw3") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayCardDraw()
    end
    if(tileType == "Burn") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayFlame()
    end
    if(tileType == "Recharge") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayUpgrade()
    end
    if(tileType == "Dome") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayShield()
    end
end

function GetTileHelp(tileType)
    if(tileType == "Teleport") then
        return "Moves the player to the other teleport tile"
    end
    if(tileType == "Mine") then
        return "Deals 1 damage to the player"
    end
    if(tileType == "Snare") then
        return "Deals 2 damage to the player"
    end
    if(tileType == "Anomaly") then
        return "Returns the player back to the checkpoint"
    end
    if(tileType == "Draw") then
        return "Player draws a card"
    end
    if(tileType == "Draw2") then
        return "Player draws 2 cards"
    end
    if(tileType == "Draw3") then
        return "Player draws 3 cards"
    end
    if(tileType == "Burn") then
        return "Player discards 1 random card from hand"
    end
    if(tileType == "Recharge") then
        return "Increase health by 1"
    end
    if(tileType == "Dome") then
        return "Player is immune to any opponent attack while on this tile"
    end
end
    

function GetPiece(id)
    return piecesGameObject.transform:GetChild(id-1).gameObject
end

function SetTeleportTileLocations()
    teleportTileLocations = {}
    for i = 0,self.transform.childCount-1,1
    do 
        if(tiles[i]:GetComponent("BoardTile").GetType() == "Teleport") then
            table.insert(teleportTileLocations,i)
        end
    end
end

function SetIndicator(id, isActive)
    GetPiece(id).transform:Find("Alien_01/Indicator").gameObject:SetActive(isActive) 
end

function SwapPieces()
    local temp = location[1]
    location[1] = location[2]
    location[2] = temp
    SetPiecePosition(1)
    SetPiecePosition(2)
end

function MovePieceToLocation(_id,_newLocation)
    location[_id] = _newLocation
    SetPiecePosition(_id)
end

function Initialize(_gameIndex,_racers,p1,p2,randomBoard)
    isInitialized = true
    SetupBoard(randomBoard)
    laps = {1,1}
    location = {0,0}
    health = {4,4}
    racers = _racers
    gameIndex = _gameIndex
    SetPiecePosition(1)
    SetPiecePosition(2)
    SetIndicator(1, p1 == client.localPlayer)
    SetIndicator(2, p2 == client.localPlayer)
    SetTeleportTileLocations()
    cardManager.Initialize(racers,self)
    audioManagerGameObject:GetComponent("AudioManager"):PlayRaceStart()
end

function Uninitialize()
    isInitialized = false
end

function SetupBoard(randomBoard)
    for i = 1, #randomBoard do
        tiles[i]:GetComponent("BoardTile").SetType( randomBoard[i] )
    end
end

function SetPiecePosition(id)
    local offset
    if(id == 1) then offset = 0.4 else offset = -0.4 end
    GetPiece(id).transform.position = tiles[location[id]].transform.position + Vector3.new(offset, 0.41, 0)
    GetPiece(id).transform.eulerAngles = GetTileRotation(location[id])
end

function GetTileRotation(_location)
    for i = _location,0,-1
    do 
        if(tiles[i]:GetComponent("BoardTile").GetRotatePiece()) then
            return tiles[i]:GetComponent("BoardTile").GetTargetRotation()
        end
    end
end

function Move(id,roll,_onMoveFinished)
    local modifiedRoll = roll
    if(cardManager.GetPlayedCard() == "Nos") then modifiedRoll = roll*2 end
    if(cardManager.GetPlayedCard() == "WarpDrive") then modifiedRoll = roll*3 end
    onMoveFinished = _onMoveFinished
    if(cardManager.GetDebugRoll() ~= nil) then
         modifiedRoll = cardManager.GetDebugRoll()
         cardManager.SetDebugRoll(nil)
    end
    playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
        player = racers:GetFromId(id).player.name,
        text  = "Rolled "..tostring(roll),
        help = "Moved "..tostring(modifiedRoll).." Tiles"
    })
    audioManagerGameObject:GetComponent("AudioManager"):PlayDiceRoll()
    cardManager._DiceAnimation(id,roll)
    Timer.new(1.5,function() _MovePiece(id,modifiedRoll) end,false)
end

function LandedOnTile(id)
    if(not isInitialized)then return end
    local tileType = tiles[location[id]]:GetComponent("BoardTile").GetType()
    if(tileType == "Draw") then
        cardManager.LandedOnDrawCardTile(1)
    elseif(tileType == "Draw2") then
            cardManager.LandedOnDrawCardTile(2)
    elseif(tileType == "Draw3") then
            cardManager.LandedOnDrawCardTile(3)
    elseif(tileType == "Teleport") then
        local destination
        if(location[id] == teleportTileLocations[1] ) then
            destination = teleportTileLocations[2] 
        else 
            destination = teleportTileLocations[1]
        end
        SetSyncedLocation(id, destination)
    elseif(tileType == "Mine") then
        SetSyncedHealth(id,health[id]-1)
    elseif(tileType == "Snare") then
        SetSyncedHealth(id,health[id]-2)
    elseif(tileType == "Recharge") then
        SetSyncedHealth(id,health[id]+1)
    elseif(tileType == "Anomaly") then
        SetSyncedLocation(id, 0)
    elseif(tileType == "Burn") then
        cardManager.DiscardCards(racers:GetPlayerWhoseTurnItIs(),1)
    end
    SyncedLandedOnSpecialTile(racers:GetPlayerWhoseTurnItIs(),tileType)
end

function _MovePiece(id, amount)
    if(not isInitialized) then return end
    if( amount == 0 ) then
        -- This is the final tile
        if(racers:GetPlayerWhoseTurnItIs() == client.localPlayer or racers:GetPlayerWhoseTurnItIs().isBot ~= nil) then
            LandedOnTile(id)
        end
        onMoveFinished()
        return
    end
    location[id] += 1
    if( location[id] == #tiles + 1) then
        if(laps[id] == TotalLaps ) then
            location[id] = 0
            SetPiecePosition(id)
            matchmaker.GameFinished(gameIndex,racers:GetPlayerWhoseTurnItIs())
            return
        end
        audioManagerGameObject:GetComponent("AudioManager"):PlayCheckpoint()
        laps[id] += 1
        location[id] = 0
        racers:GetFromId(id).lap = laps[id]
    end
    SetPiecePosition(id)
    audioManagerGameObject:GetComponent("AudioManager"):PlayMove()
    amount -= 1
    Timer.new(0.25,function() _MovePiece(id, amount) end,false)
end

function GetHealth()
    return health
end

function GetLocation()
    return location
end

function GetCardManager()
    return cardManager
end

function SetLaps(_newLaps)
    laps = _newLaps
end