--!Type(Client)

--!SerializeField
local matchmakerGameObject : GameObject = nil

local botTapHandlerOutline
local humanTapHandlerOutline
local matchmaker

function self:ClientAwake()
    SetReferences()
    SetState("ModeSelection")
    self.transform:Find("ModeSelectionGroup/PlayButton"):GetComponent(TapHandler).Tapped:Connect(function()
        local isHuman = humanTapHandlerOutline.enabled
        print("Start Match with : "..(isHuman and "Human" or "Bot"))
        if(isHuman) then
            SetState("WaitingForPlayers")
            matchmaker.EnterMatchmaking()
        end
    end)
    self.transform:Find("ModeSelectionGroup/HumanTapHandler"):GetComponent(TapHandler).Tapped:Connect(function()
        humanTapHandlerOutline.enabled = true
        botTapHandlerOutline.enabled = false
    end)
    self.transform:Find("ModeSelectionGroup/BotTapHandler"):GetComponent(TapHandler).Tapped:Connect(function()
        humanTapHandlerOutline.enabled = false
        botTapHandlerOutline.enabled = true
    end)
    self.transform:Find("WaitingForPlayersGroup/BackButton"):GetComponent(TapHandler).Tapped:Connect(function()
        SetState("ModeSelection")
        matchmaker.ExitMatchmaking()
    end)
end

function SetReferences()
    matchmaker = matchmakerGameObject:GetComponent("Matchmaker")
    botTapHandlerOutline = self.transform:Find("ModeSelectionGroup/BotTapHandler").gameObject:GetComponent(MeshRenderer)
    humanTapHandlerOutline = self.transform:Find("ModeSelectionGroup/HumanTapHandler").gameObject:GetComponent(MeshRenderer)
end

function SetState(state)
    self.transform:Find("WaitingForPlayersGroup").gameObject:SetActive(state == "WaitingForPlayers")
    self.transform:Find("ModeSelectionGroup").gameObject:SetActive(state == "ModeSelection")
end

