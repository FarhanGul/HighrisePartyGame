--!Type(Module)

--!SerializeField
local matchmakerGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local racerUIViewGameObject : GameObject = nil

local matchmaker
local cardManager
local audioManager
local racerUIView

function self:ClientAwake()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    cardManager = cardManagerGameObject:GetComponent("CardManager")
    audioManager = audioManagerGameObject:GetComponent("AudioManager")
    racerUIView = racerUIViewGameObject:GetComponent("RacerUIView")
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

function RacerUIView()
    return racerUIView
end
