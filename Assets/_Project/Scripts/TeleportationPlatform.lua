--!Type(Client)

local refs = require("References")
local common = require("Common")

-- Possible Values : Player1 , Player2 , Bot
--!SerializeField
local type : string = ""

function self:ClientStart()
    refs.Matchmaker().SubscribeOnSlotStatusUpdated(HandleOnSlotStatusUpdated)
    refs.Matchmaker().RequestSlotStatus()
end

function self:OnTriggerEnter(other : Collider)
    if(type == "Bot")then
        refs.AudioManager().PlayClick()
        refs.Matchmaker().StartBotMatch()
    elseif(type == "Player1" or type == "Player2") then
        local _player = other.gameObject:GetComponent(Character).player
        if(_player == client.localPlayer) then
            refs.AudioManager().PlayClick()
            refs.Matchmaker().EnterMatchmaking(type == "Player1" and 1 or 2)
        end
    end
end

function self:OnTriggerExit(other : Collider)
    if(type == "Player1" or type == "Player2") then
        local _player = other.gameObject:GetComponent(Character).player
        if(_player == client.localPlayer) then
            refs.AudioManager().PlayClick()
            refs.Matchmaker().ExitMatchmaking()
        end
    end
end

function HandleOnSlotStatusUpdated(slot,player)
    if( (type == "Player1" and slot == 1) or (type == "Player2" and slot == 2) ) then
        -- print("Handle On Slot Status Updated : "..slot..(player == nil and "nil" or player.name))
        self.transform:Find("WhiteStrip").gameObject:SetActive(player ~= nil)
        self.transform:Find("BlackStrip").gameObject:SetActive(player == nil)
    end
end