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

local tiles = {}
local location = {0,0}
local laps = {1,1}
local matchmaker
local cardManager
local gameIndex
local racers
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

function Initialize(_gameIndex,_racers,p1,p2)
    laps = {1,1}
    location = {0,0}
    racers = _racers
    gameIndex = _gameIndex
    SetPiecePosition(1)
    SetPiecePosition(2)
    cardManager.Initialize(racers)
end

function SetPiecePosition(id)
    local offset
    if(id == 1) then offset = 0.4 else offset = -0.4 end
    GetPiece(id).transform.position = tiles[location[id]].transform.position + Vector3.new(offset, 0.19, 0)
end

function Move(id,roll,_onMoveFinished)
    local modifiedRoll = roll
    if(cardManager.GetPlayedCard() == "Nos") then modifiedRoll = roll*2 end
    onMoveFinished = _onMoveFinished
    -- if(Input.isAltPressed) then modifiedRoll = 25 end
    _DiceAnimation(roll)
    _MovePiece(id,modifiedRoll)
end

function TurnChanged()
    cardManager.TurnChanged()
end

function _MovePiece(id, amount)
    if( amount == 0 ) then
        -- This is the final tile
        if(racers:GetPlayerWhoseTurnItIs() == client.localPlayer) then
            -- print("Temporarily treating every tile as Draw Tile")
            if(tiles[location[id]]:GetComponent("BoardTile")).GetType() == "Draw" then
                cardManager.LandedOnDrawCardTile()
            end
        end
        onMoveFinished()
        return
    end
    location[id] += 1
    if( location[id] == #tiles + 1) then
        if(laps[id] == TotalLaps ) then
            matchmaker.GameFinished(gameIndex)
            return
        end
        laps[id] += 1
        location[id] = 0
        racers:GetFromId(id).lap = laps[id]
        playerHudGameObject:GetComponent("RacerUIView").UpdateView()
    end
    SetPiecePosition(id)
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
end