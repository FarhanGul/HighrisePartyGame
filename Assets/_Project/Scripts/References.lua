--!Type(Module)

--!SerializeField
local matchmakerGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil

local matchmaker
local cardManager
local audioManager

function self:ClientAwake()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    cardManager = cardManagerGameObject:GetComponent("CardManager")
    audioManager = audioManagerGameObject:GetComponent("AudioManager")
end

function Matchmaker()
    return matchmaker
end

function CardManager()
    return cardManager
end

function AudioManager()
    return audioManager
end
