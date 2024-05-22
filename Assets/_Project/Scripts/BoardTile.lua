--!SerializeField
local type : string = "Default"
--!SerializeField
local rotatePiece : boolean = false
--!SerializeField
local targetRotation : Vector3 = Vector3.new(0, 0, 0)

function GetType()
    return type
end

function SetType(_newType)
    type = _newType
    local tilesRoot = self.gameObject.transform:Find("Tiles")
    for i=0, tilesRoot.childCount - 1 do
        local child = tilesRoot:GetChild(i).gameObject
        child:SetActive(type == child.name)
    end
end

function GetRotatePiece()
    return rotatePiece
end

function GetTargetRotation()
    return targetRotation
end