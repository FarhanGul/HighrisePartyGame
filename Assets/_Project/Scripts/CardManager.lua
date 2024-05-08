-- Public
--!SerializeField
local playCardTapHandler : TapHandler = nil
--!SerializeField
local cardSlot_01 : TapHandler = nil
--!SerializeField
local cardSlot_02 : TapHandler = nil
--!SerializeField
local cardSlot_03 : TapHandler = nil

-- Private
local cards = {}
local selectedCard
local racers

-- Events
local e_sendInitializeToServer = Event.new("sendInitializeToServer")
local e_sendDrawCardToServer = Event.new("sendDrawCardToServer")
local e_sendCardsToClient = Event.new("sendCardsToClient")

function self:ClientAwake()
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)
    e_sendCardsToClient:Connect(function(player,_cards)
        cards = _cards
        print("Client received cards - player.id: "..player.id.." client.localPlayer.id: "..client.localPlayer.id)
        if(client.localPlayer == player)then
            print(client.localPlayer.name.." recieved cards from server and updated view")
            if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
            UpdateView()
        end
    end)
end

function self:ServerAwake()
    e_sendInitializeToServer:Connect(function(player)
        -- print("Server recieved Initialize request from "..player.name)
        print("Server recieved Initialize request - player.id: "..player.id)
        cards[player] = {}
        e_sendCardsToClient:FireAllClients(player,cards)
    end)
    e_sendDrawCardToServer:Connect(function(player)
        if(#cards[player] < 3) then
            local deck = {"Nos","Zap"}
            local newCard = deck[math.random(1,2)]
            table.insert(cards[player],newCard)
            e_sendCardsToClient:FireAllClients(player,cards)
        end
    end)
end

function LandedOnDrawCardTile()
    -- print(client.localPlayer.name.." Sent Draw request to server")
    e_sendDrawCardToServer:FireServer() 
end

function Initialize(_racers)
    e_sendInitializeToServer:FireServer() 
    print("Initialize Request sent to server- client.localPlayer.id: "..client.localPlayer.id)
    -- print(client.localPlayer.name.." Sent Initialize request to server")
    racers = _racers
end

function PlaySelectedCard()
    print("Card Played : "..cards[client.localPlayer][selectedCard])
end

function CardSlotClick(cardSlotIndex)
    selectedCard = cardSlotIndex
    UpdateView()
end

function UpdateView()
    local c = cards[client.localPlayer]
    playCardTapHandler.gameObject:SetActive(#c > 0 and racers.IsLocalRacerTurn())
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
        ActivateCardInSlot(slots[i], c[i], i == selectedCard)
    end
end

function ActivateCardInSlot(cardSlot,card,isSelected)
    for i=0,2 do
        local child = cardSlot.transform:GetChild(i).gameObject
        child:SetActive(card == child.name)
    end
    cardSlot.transform:Find("Outline").gameObject:SetActive(isSelected)
end