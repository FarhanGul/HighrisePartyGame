--!SerializeField
local type : string = "Default"
--!SerializeField
local rotatePiece : boolean = false
--!SerializeField
local targetRotation : Vector3 = Vector3.new(0, 0, 0)

function GetType()
    return type
end

function GetRotatePiece()
    return rotatePiece
end

function GetTargetRotation()
    return targetRotation
end