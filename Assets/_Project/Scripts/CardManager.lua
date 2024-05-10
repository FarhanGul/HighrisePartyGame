-- Public
--!SerializeField
local playCardTapHandler : TapHandler = nil
--!SerializeField
local cardSlot_01 : TapHandler = nil
--!SerializeField
local cardSlot_02 : TapHandler = nil
--!SerializeField
local cardSlot_03 : TapHandler = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil

-- Private
local cards = {}
local selectedCard
local racers
local playedCard = nil

-- Events
local e_sendInitializeToServer = Event.new("sendInitializeToServer")
local e_sendDrawCardToServer = Event.new("sendDrawCardToServer")
local e_sendCardsToClient = Event.new("sendCardsToClient")
local e_sendPlayCardToServer = Event.new("sendPlayCardToServer")
local e_sendPlayCardToClient = Event.new("sendPlayCardToClient")

function self:ClientAwake()
    print("Client registered event - client.localPlayer.id: "..client.localPlayer.id)
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)
    e_sendCardsToClient:Connect(function(_cards)
        cards = _cards
        print("Client received cards - client.localPlayer.id: "..client.localPlayer.id)
        if(cards[client.localPlayer] ~= nil)then
            -- print(client.localPlayer.name.." recieved cards from server and updated view")
            if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
            UpdateView()
        end
    end)
    e_sendPlayCardToClient:Connect(function(_playedCard)
        print("Card Played : ".._playedCard)
        playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
            player = client.localPlayer.name,
            text  = "Played ".._playedCard
        })
        if(_playedCard == "Zap") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayZap()
        elseif(_playedCard == "Nos") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayNos()
        elseif(_playedCard == "Honk") then
            audioManagerGameObject:GetComponent("AudioManager"):PlayHonk()
        end
        playedCard = _playedCard
    end)
end

function GetPlayedCard()
    return playedCard
end

function self:ServerAwake()
    e_sendInitializeToServer:Connect(function(player)
        -- print("Server recieved Initialize request from "..player.name)
        print("Server recieved Initialize request - player.id: "..player.id)
        cards[player] = {}
        e_sendCardsToClient:FireAllClients(cards)
    end)
    e_sendDrawCardToServer:Connect(function(player)
        if(#cards[player] < 3) then
            local deck = {"Nos","Zap"}
            local newCard = deck[math.random(1,2)]
            table.insert(cards[player],newCard)
            e_sendCardsToClient:FireAllClients(cards)
        end
    end)
    e_sendPlayCardToServer:Connect(function(player,_playedCard)
        table.remove(cards[player],table.find(cards[player], _playedCard))
        e_sendCardsToClient:FireAllClients(cards)
        e_sendPlayCardToClient:FireAllClients(_playedCard)
    end
    )
end

function LandedOnDrawCardTile()
    -- print(client.localPlayer.name.." Sent Draw request to server")
    e_sendDrawCardToServer:FireServer() 
    audioManagerGameObject:GetComponent("AudioManager"):PlayCardDraw()
end

function Initialize(_racers)
    e_sendInitializeToServer:FireServer() 
    -- print("Initialize Request sent to server- client.localPlayer.id: "..client.localPlayer.id)
    -- print(client.localPlayer.name.." Sent Initialize request to server")
    racers = _racers
end

function TurnChanged()
    playedCard = nil
    UpdateView()
end


function PlaySelectedCard()
    local playedCard = cards[client.localPlayer][selectedCard]
    e_sendPlayCardToServer:FireServer(playedCard) 
    audioManagerGameObject:GetComponent("AudioManager"):PlayClick()
end

function CardSlotClick(cardSlotIndex)
    selectedCard = cardSlotIndex
    audioManagerGameObject:GetComponent("AudioManager"):PlayHit()
    UpdateView()
end

function UpdateView()
    local c = cards[client.localPlayer]
    local canPlayCard = #c > 0 and racers.IsLocalRacerTurn() and playedCard == nil
    playCardTapHandler.gameObject:SetActive(canPlayCard)
    cardSlot_01.gameObject:SetActive(#c > 0)
    cardSlot_02.gameObject:SetActive(#c > 1)
    cardSlot_03.gameObject:SetActive(#c > 2)
    if(#c == 1) then
        cardSlot_01.transform.localPosition = Vector3.new(0, 0, 0)
    elseif(#c == 2) then 
        cardSlot_01.transform.localPosition = Vector3.new(-0.5, 0, 0)
        cardSlot_02.transform.localPosition = Vector3.new(0.5, 0, 0)
    elseif(#c == 3) then 
        cardSlot_01.transform.localPosition = Vector3.new(-1.05, 0, 0)
        cardSlot_02.transform.localPosition = Vector3.new(0, 0, 0)
        cardSlot_03.transform.localPosition = Vector3.new(1.05, 0, 0)
    end
    local slots = {cardSlot_01,cardSlot_02, cardSlot_03}
    for i = 1 , #c do
        ActivateCardInSlot(slots[i], c[i], i == selectedCard and canPlayCard)
    end
end

function ActivateCardInSlot(cardSlot,card,isSelected)
    for i=0,2 do
        local child = cardSlot.transform:GetChild(i).gameObject
        child:SetActive(card == child.name)
    end
    cardSlot.transform:Find("Outline").gameObject:SetActive(isSelected)
end