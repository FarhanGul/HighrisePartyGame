--!SerializeField
local piece : GameObject = nil
local tiles = {}
local location = 0
--!SerializeField
local dice : GameObject = nil

function self:Start()
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i]= self.transform.GetChild(self.transform,i).gameObject;
    end
end

function Move(roll)
    print(roll)
    _DiceAnimation(roll)
    _MovePiece(roll)
end

function _MovePiece(amount)
    if( location >= #tiles or amount == 0 )
    then
        return
    end
    location += 1
    piece.transform.position = tiles[location].transform.position
    amount -= 1
    local newTimer = Timer.new(0.25,function() _MovePiece(amount) end,false)
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