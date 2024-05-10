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
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)
    e_sendCardsToClient:Connect(function(_cards)
        cards = _cards
        if(cards[client.localPlayer] ~= nil)then
            if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
            UpdateView()
        end
    end)
    e_sendPlayCardToClient:Connect(function(_playedCard)
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
        cards[player] = {}
    end)
    e_sendDrawCardToServer:Connect(function(player,opponentPlayer)
        if(#cards[player] < 3) then
            local deck = {"Nos","Zap","Honk"}
            local newCard = deck[math.random(1,#deck)]
            table.insert(cards[player],newCard)
            e_sendCardsToClient:FireClient(player,cards)
            e_sendCardsToClient:FireClient(opponentPlayer,cards)
        end
    end)
    e_sendPlayCardToServer:Connect(function(player,opponentPlayer,_playedCard)
        table.remove(cards[player],table.find(cards[player], _playedCard))
        e_sendCardsToClient:FireClient(player,cards)
        e_sendCardsToClient:FireClient(opponentPlayer,cards)
        e_sendPlayCardToClient:FireClient(player,_playedCard)
        e_sendPlayCardToClient:FireClient(opponentPlayer,_playedCard)
    end
    )
end

function LandedOnDrawCardTile()
    e_sendDrawCardToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer)) 
    if(#cards[client.localPlayer] ~= 3) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayCardDraw()
    end
end

function Initialize(_racers)
    racers = _racers
    cards[client.localPlayer] = {}
    cards[racers:GetOpponentPlayer(client.localPlayer)] = {}
    e_sendInitializeToServer:FireServer() 
    selectedCard = -1
    UpdateView()
end

function TurnChanged()
    playedCard = nil
    UpdateView()
end

function PlaySelectedCard()
    playedCard = cards[client.localPlayer][selectedCard]
    e_sendPlayCardToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),playedCard) 
    audioManagerGameObject:GetComponent("AudioManager"):PlayClick()
    UpdateView()
end

function CardSlotClick(cardSlotIndex)
    if(CanPlaycard() and selectedCard ~= cardSlotIndex) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayHit()
    end
    selectedCard = cardSlotIndex
    -- print("Can Play Card :"..tostring(CanPlaycard()))
    -- print("selectedCard ~= cardSlotIndex:"..tostring(selectedCard ~= cardSlotIndex))
    UpdateView()
end

function CanPlaycard()
    return #cards[client.localPlayer] > 0 and racers.IsLocalRacerTurn() and playedCard == nil
end

function UpdateView()
    local c = cards[client.localPlayer]
    local canPlayCard = CanPlaycard()
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
    for i=0,cardSlot.transform.childCount - 1 do
        local child = cardSlot.transform:GetChild(i).gameObject
        child:SetActive(card == child.name)
    end
    cardSlot.transform:Find("Outline").gameObject:SetActive(isSelected)
end