--!SerializeField
local dice : GameObject = nil
--!SerializeField
local piecesGameObject : GameObject = nil
--!SerializeField
local matchmakerGameObject : GameObject = nil

local tiles = {}
local location = {}
local matchmaker
local gameIndex

function self:Start()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i]= self.transform.GetChild(self.transform,i).gameObject;
    end
end

function GetPiece(id)
    return piecesGameObject.transform:GetChild(id-1).gameObject
end

function Initialize(_gameIndex)
    gameIndex = _gameIndex
    local i = 1
    for k,v in pairs(location) do
        v = 0
        if(i == 1) then offset = 0.15 else offset = -0.15 end
        k.transform.position = tiles[0].transform.position + Vector3.new(offset, 0, 0)
        i += 1
    end
end

function SetPiecePosition(id)
    local piece = GetPiece(id)
    local offset
    if(id == 1) then offset = 0.15 else offset = -0.15 end
    piece.transform.position = tiles[location[piece]].transform.position + Vector3.new(offset, 0, 0)
end

function Move(id,roll)
    _DiceAnimation(roll)
    _MovePiece(id,roll)
end

function _MovePiece(id, amount)
    local piece = GetPiece(id)
    if( location[piece] == nil) then
        location[piece] = 0
    end
    if( location[piece] >= #tiles or amount == 0 )
    then
        return
    end
    location[piece] += 1
    SetPiecePosition(id)
    amount -= 1
    if( location[piece] == #tiles) then
        matchmaker.GameFinished(gameIndex)
        return
    end
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