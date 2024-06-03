--!Type(Client)

local boardGenerator = require("BoardGenerator")

--!SerializeField
local matchmakerGameObject : GameObject = nil

--!SerializeField
local raceGameObject : GameObject = nil

--!SerializeField
local audioManagerGameObject : GameObject = nil

local botTapHandlerOutline
local humanTapHandlerOutline
local matchmaker
local raceGame
local audioManager

function self:ClientAwake()
    SetReferences()
    SetState("ModeSelection")
    self.transform:Find("ModeSelectionGroup/PlayButton"):GetComponent(TapHandler).Tapped:Connect(function()
        audioManager.PlayClick()
        local isHuman = humanTapHandlerOutline.enabled
        if(isHuman) then
            SetState("WaitingForPlayers")
        else
            matchmaker.StartBotMatch()
        end
    end)
    self.transform:Find("ModeSelectionGroup/HumanTapHandler"):GetComponent(TapHandler).Tapped:Connect(function()
        audioManager.PlayHit()
        humanTapHandlerOutline.enabled = true
        botTapHandlerOutline.enabled = false
    end)
    self.transform:Find("ModeSelectionGroup/BotTapHandler"):GetComponent(TapHandler).Tapped:Connect(function()
        audioManager.PlayHit()
        humanTapHandlerOutline.enabled = false
        botTapHandlerOutline.enabled = true
    end)
    self.transform:Find("WaitingForPlayersGroup/BackButton"):GetComponent(TapHandler).Tapped:Connect(function()
        audioManager.PlayClick()
        SetState("ModeSelection")
        matchmaker.ExitMatchmaking()
    end)
end

function SetReferences()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    raceGame = raceGameObject:GetComponent("RaceGame")
    audioManager = audioManagerGameObject:GetComponent("AudioManager")
    botTapHandlerOutline = self.transform:Find("ModeSelectionGroup/BotTapHandler").gameObject:GetComponent(MeshRenderer)
    humanTapHandlerOutline = self.transform:Find("ModeSelectionGroup/HumanTapHandler").gameObject:GetComponent(MeshRenderer)
end

function SetState(state)
    self.transform:Find("WaitingForPlayersGroup").gameObject:SetActive(state == "WaitingForPlayers")
    self.transform:Find("ModeSelectionGroup").gameObject:SetActive(state == "ModeSelection")
end

