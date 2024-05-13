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
local board = nil

-- Events
local e_sendInitializeToServer = Event.new("sendInitializeToServer")
local e_sendHandDiscardedToServer = Event.new("sendHandDiscardedToServer")
local e_sendDrawCardToServer = Event.new("sendDrawCardToServer")
local e_sendCardsToClient = Event.new("sendCardsToClient")
local e_sendPlayCardToServer = Event.new("sendPlayCardToServer")
local e_sendPlayCardToClient = Event.new("sendPlayCardToClient")

function self:ServerAwake()
    e_sendInitializeToServer:Connect(function(player)
        cards[player] = {}
    end)
    e_sendHandDiscardedToServer:Connect(function(player,opponentPlayer)
        cards[player] = {}
        e_sendCardsToClient:FireClient(player,cards)
        e_sendCardsToClient:FireClient(opponentPlayer,cards)
    end)
    e_sendDrawCardToServer:Connect(function(player,opponentPlayer,count)
        if(#cards[player] < 3) then
            local cardsToDraw = math.min(count,3 - #cards[player])
            for i = 1, cardsToDraw do
                local newCard = GetRandomCard()
                table.insert(cards[player],newCard)
            end
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

function self:ClientAwake()
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)
    e_sendCardsToClient:Connect(function(_cards)
        cards = _cards
        if(cards[client.localPlayer] ~= nil)then
            if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
            playerHudGameObject:GetComponent("RacerUIView").UpdateView()
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
        elseif(_playedCard == "WarpDrive") then
            print("Missing Warp Drive sound effect")
        elseif(_playedCard == "WormHole") then
            board.SwapPieces()
            print("Missing Worm Hole sound effect")
        end
        playedCard = _playedCard
    end)
end

function SendHandDiscardedToServer(player)
    if(#cards[player] > 0) then
        e_sendHandDiscardedToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer)) 
    end
end

function GetPlayedCard()
    return playedCard
end

function GetRandomCard()
    local deck = {
        {card="Nos",probablity=1},
        {card="Zap",probablity=1},
        {card="Honk",probablity=1},
        {card="WarpDrive",probablity=0.5},
        {card="WormHole",probablity=0.4}
    }
    local rand = math.random()
    local filterdCards = {}
    for k , v in pairs(deck) do
        if v.probablity >= rand then
            table.insert(filterdCards,v.card)
        end
    end
    return filterdCards[math.random(1,#filterdCards)]
end

function LandedOnDrawCardTile(count)
    e_sendDrawCardToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),count) 
    if(#cards[client.localPlayer] ~= 3) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayCardDraw()
    end
end

function Initialize(_racers, _board)
    board = _board
    racers = _racers
    cards[client.localPlayer] = {}
    cards[racers:GetOpponentPlayer(client.localPlayer)] = {}
    e_sendInitializeToServer:FireServer() 
    selectedCard = -1
    UpdateView()
end

function TurnEnd()
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

function GetCardCount(player)
    return #cards[player]
end