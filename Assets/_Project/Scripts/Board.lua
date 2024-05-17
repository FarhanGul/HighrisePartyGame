-- Constants
local TotalLaps = 3

--!SerializeField
local dice : GameObject = nil
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
local location = {0,0}
local overclock = {0,0}
local laps = {1,1}
local matchmaker
local cardManager
local gameIndex
local racers
local teleportTileLocations
local onMoveFinished

-- Events
local e_sendOverclockToServer = Event.new("sendOverclockToServer")
local e_sendOverclockToClient = Event.new("sendOverclockToClient")
local e_sendLocationToServer = Event.new("sendLocationToServer")
local e_sendLocationToClient = Event.new("sendLocationToClient")
local e_sendLandedOnSpecialTileToServer = Event.new("sendLandedOnSpecialTileToServer")
local e_sendLandedOnSpecialTileToClient = Event.new("sendLandedOnSpecialTileToClient")

function self:ServerAwake()
    e_sendOverclockToServer:Connect(function(player,opponentPlayer,id,_overclock)
        e_sendOverclockToClient:FireClient(player,id,_overclock)
        e_sendOverclockToClient:FireClient(opponentPlayer,id,_overclock)
    end)
    e_sendLocationToServer:Connect(function(player,opponentPlayer,id,_location)
        e_sendLocationToClient:FireClient(player,id,_location)
        e_sendLocationToClient:FireClient(opponentPlayer,id,_location)
    end)
    e_sendLandedOnSpecialTileToServer:Connect(function(player,opponentPlayer,playerName,tileType)
        e_sendLandedOnSpecialTileToClient:FireClient(player,playerName,tileType)
        e_sendLandedOnSpecialTileToClient:FireClient(opponentPlayer,playerName,tileType)
    end)
end

function self:ClientAwake()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    cardManager = cardManagerGameObject:GetComponent("CardManager")
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i] = self.transform.GetChild(self.transform,i).gameObject;
    end
    e_sendOverclockToClient:Connect(function(id,_overclock)
        overclock[id] = _overclock
        playerHudGameObject:GetComponent("RacerUIView").UpdateGameView()
    end)
    e_sendLocationToClient:Connect(function(id,_location)
        location[id] = _location
        SetPiecePosition(id)
    end)
    e_sendLandedOnSpecialTileToClient:Connect(function(playerName,tileType)
        if(tileType == "Teleport") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayTeleport()
        end
        if(tileType == "Overclock") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayUpgrade()
        end
        if(tileType == "Anomaly") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayAnomaly()
        end
        if(tileType ~= "Default")then
            local label = tileType
            if(label == "Draw3") then label = "Draw 3x" end
            playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
                player = playerName,
                text  = "Landed on  "..label
            })
        end
    end)
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

function SwapPieces()
    local temp = location[1]
    location[1] = location[2]
    location[2] = temp
    SetPiecePosition(1)
    SetPiecePosition(2)
end

function Initialize(_gameIndex,_racers,p1,p2)
    -- print("Board Initialized :"..tostring(_racers == nil))
    laps = {1,1}
    location = {0,0}
    overclock = {0,0}
    racers = _racers
    print(client.localPlayer.name.."@".."Board Racer count : "..racers:GetCount())
    gameIndex = _gameIndex
    SetPiecePosition(1)
    SetPiecePosition(2)
    SetTeleportTileLocations()
    cardManager.Initialize(racers,self)
    audioManagerGameObject:GetComponent("AudioManager"):PlayRaceStart()
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
    -- print("Move "..tostring(racers == nil))
    -- print("Move "..tostring(racers:GetFromId(id) == nil))
    playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
        player = racers:GetFromId(id).player.name,
        text  = "Rolled "..tostring(roll)
    })
    local modifiedRoll = roll
    if(cardManager.GetPlayedCard() == "Nos") then modifiedRoll = roll*2 end
    if(cardManager.GetPlayedCard() == "WarpDrive") then modifiedRoll = roll*3 end
    modifiedRoll += overclock[id]
    onMoveFinished = _onMoveFinished
    if(Input.isAltPressed) then
        print("Debug Role Activated")
         modifiedRoll = 3 
    end
    cardManager._DiceAnimation(id,roll)
    Timer.new(1.5,function() _MovePiece(id,modifiedRoll) end,false)
end

function LandedOnTile(id)
    local tileType = tiles[location[id]]:GetComponent("BoardTile").GetType()
    if(tileType == "Draw") then
        cardManager.LandedOnDrawCardTile(1)
    elseif(tileType == "Draw3") then
            cardManager.LandedOnDrawCardTile(3)
    elseif(tileType == "Teleport") then
        local destination
        if(location[id] == teleportTileLocations[1] ) then
            destination = teleportTileLocations[2] 
        else 
            destination = teleportTileLocations[1]
        end
        e_sendLocationToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),id,destination)
    elseif(tileType == "Overclock") then
        e_sendOverclockToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),id,GetNextOverclockValue(overclock[id]))
    elseif(tileType == "Anomaly") then
        e_sendOverclockToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),id,0)
        cardManager.SendHandDiscardedToServer(client.localPlayer)
        e_sendLocationToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),id,0)
    end
    e_sendLandedOnSpecialTileToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),client.localPlayer.name,tileType)
end

function GetNextOverclockValue(current)
    if(current == 0 ) then return 1
    else return current*2 end
end

function _MovePiece(id, amount)
    if( amount == 0 ) then
        -- This is the final tile
        if(racers:GetPlayerWhoseTurnItIs() == client.localPlayer) then
            LandedOnTile(id)
        end
        onMoveFinished()
        return
    end
    location[id] += 1
    if( location[id] == #tiles + 1) then
        if(laps[id] == TotalLaps ) then
            audioManagerGameObject:GetComponent("AudioManager"):PlayResultNotify()
            matchmaker.GameFinished(gameIndex)
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
    local newTimer = Timer.new(0.25,function() _MovePiece(id, amount) end,false)
end

function GetOverclock()
    return overclock
end

function GetCardManager()
    return cardManager
end