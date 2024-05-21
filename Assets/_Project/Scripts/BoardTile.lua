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
    for i=0, self.transform.childCount - 1 do
        local child = self.transform:GetChild(i).gameObject
        child:SetActive(type == child.name)
    end
end

function GetRotatePiece()
    return rotatePiece
end

function GetTargetRotation()
    return targetRotation
end