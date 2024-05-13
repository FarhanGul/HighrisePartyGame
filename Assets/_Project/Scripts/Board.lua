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

function self:ClientAwake()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    cardManager = cardManagerGameObject:GetComponent("CardManager")
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i] = self.transform.GetChild(self.transform,i).gameObject;
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

function SwapPieces()
    local temp = location[1]
    location[1] = location[2]
    location[2] = temp
    SetPiecePosition(1)
    SetPiecePosition(2)
end

function Initialize(_gameIndex,_racers,p1,p2)
    laps = {1,1}
    location = {0,0}
    overclock = {0,0}
    racers = _racers
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
    GetPiece(id).transform.position = tiles[location[id]].transform.position + Vector3.new(offset, 0.19, 0)
end

function Move(id,roll,_onMoveFinished)
    playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
        player = racers:GetFromId(id).player.name,
        text  = "Rolled "..tostring(roll)
    })
    local modifiedRoll = roll
    if(cardManager.GetPlayedCard() == "Nos") then modifiedRoll = roll*2 end
    if(cardManager.GetPlayedCard() == "WarpDrive") then modifiedRoll = roll*3 end
    modifiedRoll += overclock[id]
    onMoveFinished = _onMoveFinished
    if(Input.isAltPressed) then modifiedRoll = 6 end
    _DiceAnimation(roll)
    Timer.new(1.5,function() _MovePiece(id,modifiedRoll) end,false)
end

function TurnEnd()
    cardManager.TurnEnd()
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
        location[id] = destination
        SetPiecePosition(id)
        print("Missing Teleport sound effect")
    elseif(tileType == "Overclock") then
        overclock[id] += 1
    elseif(tileType == "Anomaly") then
            overclock[id] = 0
    end
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
        laps[id] += 1
        location[id] = 0
        racers:GetFromId(id).lap = laps[id]
        playerHudGameObject:GetComponent("RacerUIView").UpdateView()
    end
    SetPiecePosition(id)
    audioManagerGameObject:GetComponent("AudioManager"):PlayMove()
    amount -= 1
    local newTimer = Timer.new(0.25,function() _MovePiece(id, amount) end,false)
end

function _DiceAnimation(randomFace)
    local rotation = Vector3.new(0,0,0)
    local x, y, z = 0, 0, 0

    if (randomFace == 1) then
        x = 180
        y = 0
        z = 0
    elseif (randomFace == 2) then
        x = -90
        y = 0
        z = 0
    elseif (randomFace == 3) then
        x = 0
        y = 0
        z = -90
    elseif (randomFace == 4) then
        x = 0
        y = 0
        z = 90
    elseif (randomFace == 5) then
        x = 90
        y = 0
        z = 0
    elseif (randomFace == 6) then
        x = 0
        y = 0
        z = 0
    end

    -- Apply rotation to the cube
    rotation = Vector3.new(x,y,z)
    dice.transform.localEulerAngles = rotation
    dice.transform.GetChild(dice.transform,0).gameObject:GetComponent(Animator):SetTrigger("Flip")
    audioManagerGameObject:GetComponent("AudioManager"):PlayDiceRoll()
end