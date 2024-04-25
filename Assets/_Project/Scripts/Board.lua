--!SerializeField
local piece : GameObject = nil
local tiles = {}
local location = 0

function self:Start()
    for i = 0,self.transform.childCount-1,1
    do 
        tiles[i]= self.transform.GetChild(self.transform,i).gameObject;
    end
end

function Move(roll)
    print(roll)
    MovePiece(roll)
end

function MovePiece(amount)
    if( location >= #tiles or amount == 0 )
    then
        return
    end
    location += 1
    piece.transform.position = tiles[location].transform.position
    amount -= 1
    local newTimer = Timer.new(0.25,function() MovePiece(amount) end,false)
end