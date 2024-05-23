-- Public
--!SerializeField
local diceAnimator : Animator = nil
--!SerializeField
local diceMesh : Transform = nil
--!SerializeField
local playCardTapHandler : TapHandler = nil
--!SerializeField
local rollTapHandler : TapHandler = nil
--!SerializeField
local rollPressed : GameObject = nil
--!SerializeField
local playCardPressed : GameObject = nil
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
local isPlayCardRequestInProgress
local isRollRequestInProgress
local didRoll
local debugRoll = nil

-- Events
local e_sendCardsToServer = Event.new("sendCardsToServer")
local e_sendCardsToClient = Event.new("sendCardsToClient")
local e_sendHandDiscardedToServer = Event.new("sendHandDiscardedToServer")
local e_sendHandDiscardedToClient = Event.new("sendHandDiscardedToClient")
local e_sendDrawCardToServer = Event.new("sendDrawCardToServer")
local e_sendDrawCardToClient = Event.new("sendDrawCardToClient")
local e_sendPlayCardToServer = Event.new("sendPlayCardToServer")
local e_sendPlayCardToClient = Event.new("sendPlayCardToClient")
local e_sendRollToServer = Event.new("sendRollToServer")
local e_sendRollToClients = Event.new("sendRollToClients")

function self:ServerAwake()
    e_sendCardsToServer:Connect(function(player,opponentPlayer,_cards)
        e_sendCardsToClient:FireClient(opponentPlayer,_cards)
    end)
    e_sendHandDiscardedToServer:Connect(function(player,opponentPlayer)
        e_sendHandDiscardedToClient:FireClient(player,player)
        e_sendHandDiscardedToClient:FireClient(opponentPlayer,player)
    end)
    e_sendDrawCardToServer:Connect(function(player,playerWhoDrew,opponentPlayer,cardsToDraw)
        local newCards = {}
        for i = 1, cardsToDraw do
            table.insert(newCards,GetRandomCard())
        end
        e_sendDrawCardToClient:FireClient(playerWhoDrew,playerWhoDrew,newCards)
        e_sendDrawCardToClient:FireClient(opponentPlayer,playerWhoDrew,newCards)
    end)
    e_sendPlayCardToServer:Connect(function(player,opponentPlayer,_playedCard)
        e_sendPlayCardToClient:FireClient(player,player,_playedCard)
        e_sendPlayCardToClient:FireClient(opponentPlayer,player,_playedCard)
    end)
    e_sendRollToServer:Connect(function(player,opponentPlayer,id, roll)
        e_sendRollToClients:FireClient(player,id,roll)
        e_sendRollToClients:FireClient(opponentPlayer,id,roll)
    end)
end

function self:ClientAwake()
    print("Debug Role Activated")
    Chat.TextMessageReceivedHandler:Connect(function(channel,from,message)
        debugRoll = tonumber(message)
        Chat:DisplayTextMessage(channel, from, message)
    end)
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)

    e_sendRollToClients:Connect(function(id, roll)
        board.Move(id,roll,function() 
            local skipOpponentTurn = false
            if(GetPlayedCard() == "Zap") then skipOpponentTurn = true end
            if(not skipOpponentTurn) then
                racers:GetFromId(id).isTurn = false
                racers:GetFromId(racers.GetOtherId(id)).isTurn = true
            end
            isRollRequestInProgress = false
            TurnEnd()
        end)
    end)

    e_sendPlayCardToClient:Connect(function(_player,_playedCard)
        table.remove(cards[_player],table.find(cards[_player], _playedCard))
        HandleCardAudio(_playedCard)
        local isOpponentOnSafeTile = board.IsOnSafeTile(racers:GetOpponentRacer(_player).id)
        if ( not isOpponentOnSafeTile ) then
            if(_playedCard == "WormHole") then
                board.SwapPieces()
            elseif(_playedCard == "ElectronBlaster") then
                board.MovePieceToLocation(racers:GetOpponentRacer(_player).id,0)
            elseif(_playedCard == "MeatHook") then
                StealCards(_player, racers:GetOpponentPlayer(_player))
            elseif(_playedCard == "AntimatterCannon") then
                board.ChangeHealth(racers:GetOpponentRacer(_player).id,-1)
            elseif(_playedCard == "FlameThrower") then
                if(_player == client.localPlayer) then
                    DiscardOpponentCards(_player, 3)
                end
            end
        end
        if(_playedCard == "Regenerate") then
            board.ChangeHealth(racers:GetFromPlayer(_player).id,1)
        end
        playerHudGameObject:GetComponent("RacerUIView").UpdateAction({
            player = _player.name,
            text  = "Played ".._playedCard..(isOpponentOnSafeTile and " but was blocked" or ""),
            help = GetCardHelp(_playedCard)
        })
        playedCard = _playedCard
        isPlayCardRequestInProgress = false
        OnCardCountUpdated()
    end)

    e_sendCardsToClient:Connect(function(_cards)
        cards = _cards
        OnCardCountUpdated()
    end)

    e_sendHandDiscardedToClient:Connect(function(_playerWhoseHandIsDiscarded)
        cards[_playerWhoseHandIsDiscarded] = {}
        OnCardCountUpdated()
    end)

    e_sendDrawCardToClient:Connect(function(playerWhoDrew,newCards)
        for i = 1 , #newCards do
            table.insert(cards[playerWhoDrew],newCards[i])
        end
        OnCardCountUpdated()
    end)

    rollTapHandler.Tapped:Connect(function()
        if(racers.IsLocalRacerTurn() and not isRollRequestInProgress and not GetIsPlayCardRequestInProgress()) then
            isRollRequestInProgress = true
            didRoll = true
            SetInteractableState()
            e_sendRollToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),racers:GetRacerWhoseTurnItIs().id ,math.random(1,6)) 
        end
    end)
end

function HandleCardAudio(_card)
    if(_card == "Zap") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayZap()
    elseif(_card == "Nos") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayNos()
    elseif(_card == "Honk") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayHonk()
    elseif(_card == "WarpDrive") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayNos()
    elseif(_card == "WormHole") then
        audioManagerGameObject:GetComponent("AudioManager"):PlayTeleport()
    end
end

function DiscardOpponentCards(_otherPlayer,count)
    local _opponent = racers:GetOpponentPlayer(_otherPlayer)
    if(#cards[_opponent] > 0) then
        local cardsToDiscard = math.min(count,#cards[_opponent])
        for i = 1 , count do
            local randIndex = math.random(1, #cards[_opponent])
            table.remove(cards[_opponent],randIndex)
        end
        e_sendCardsToServer:FireServer(_opponent,cards)
        OnCardCountUpdated()
    end
end

function SetInteractableState()
    local isLocalTurn = racers.IsLocalRacerTurn()
    rollPressed:SetActive(not isLocalTurn or (isLocalTurn and isRollRequestInProgress))
    playCardPressed:SetActive(not isLocalTurn or not CanPlaycard() or didRoll)
    rollTapHandler.gameObject:SetActive(isLocalTurn and not isRollRequestInProgress)
    playCardTapHandler.gameObject:SetActive(isLocalTurn and CanPlaycard() and not didRoll)
end


function OnCardCountUpdated()
    if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
    playerHudGameObject:GetComponent("RacerUIView").UpdateGameView()
    UpdateView()
end

function SendHandDiscardedToServer(player)
    if(#cards[player] > 0) then
        e_sendHandDiscardedToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer))
    end
end

function StealCards(thief,victim)
    if(client.localPlayer == thief and #cards[victim] > 0) then
        local randomIndex = math.random(1,#cards[victim])
        table.insert(cards[thief],cards[victim][randomIndex])
        table.remove(cards[victim],randomIndex)
        e_sendCardsToServer:FireServer(victim,cards)
        OnCardCountUpdated()
    end
end

function GetPlayedCard()
    return playedCard
end

function GetCardHelp(_card)
    if(_card == "Zap") then
        return "Opponent misses their next turn"
    elseif(_card == "Nos") then
        return "Next roll is doubled"
    elseif(_card == "Honk") then
        return "This card does nothing"
    elseif(_card == "WarpDrive") then
        return "Next roll is tripled"
    elseif(_card == "WormHole") then
        return "Swap places with the opponent. Laps remain unchanged"
    elseif(_card == "ElectronBlaster") then
        return "Opponent is sent back to the checkpoint"
    elseif(_card == "MeatHook") then
        return "Steal card from opponent"
    elseif(_card == "AntimatterCannon") then
            return "Deal 1 damage to opponent"
    elseif(_card == "FlameThrower") then
        return "Discard all opponent cards"
    elseif(_card == "Regenerate") then
            return "Increase Health by 1"
    end
end

function GetRandomCard()
    local deck = {
        {card="Nos",probablity=1},
        {card="Zap",probablity=0.85},
        {card="Honk",probablity=0.3},
        {card="WarpDrive",probablity=0.3},
        {card="WormHole",probablity=0.4},
        {card="ElectronBlaster",probablity=0.4},
        {card="MeatHook",probablity=0.85},
        {card="AntimatterCannon",probablity=0.7},
        {card="FlameThrower",probablity=0.5},
        {card="Regenerate",probablity=0.7},
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
    if(#cards[racers:GetPlayerWhoseTurnItIs()] ~= 3) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayCardDraw()
    end
    local cardsToDraw = math.min(count,3 - #cards[racers:GetPlayerWhoseTurnItIs()])
    if(cardsToDraw > 0) then
        e_sendDrawCardToServer:FireServer(racers:GetPlayerWhoseTurnItIs(),racers:GetOpponentPlayer(racers:GetPlayerWhoseTurnItIs()),cardsToDraw)
    end
end

function Initialize(_racers, _board)
    board = _board
    racers = _racers
    cards = {}
    cards[client.localPlayer] = {}
    cards[racers:GetOpponentPlayer(client.localPlayer)] = {}
    selectedCard = -1
    playedCard = nil
    didRoll = false
    UpdateView()
end

function TurnEnd()
    didRoll = false
    playedCard = nil
    playerHudGameObject:GetComponent("RacerUIView").UpdateGameView()
    UpdateView()
end

function PlaySelectedCard()
    playedCard = cards[client.localPlayer][selectedCard]
    isPlayCardRequestInProgress = true
    e_sendPlayCardToServer:FireServer(racers:GetOpponentPlayer(client.localPlayer),playedCard)
    audioManagerGameObject:GetComponent("AudioManager"):PlayClick()
    UpdateView()
end

function CardSlotClick(cardSlotIndex)
    if(CanPlaycard() and selectedCard ~= cardSlotIndex) then
        audioManagerGameObject:GetComponent("AudioManager"):PlayHit()
    end
    selectedCard = cardSlotIndex
    UpdateView()
end

function GetDebugRoll()
    return debugRoll
end

function SetDebugRoll(newRoll)
    debugRoll = newRoll
end

function CanPlaycard()
    return #cards[client.localPlayer] > 0 and racers.IsLocalRacerTurn() and playedCard == nil
end

function UpdateView()
    SetInteractableState()
    local c = cards[client.localPlayer]
    local canPlayCard = CanPlaycard()
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

function GetIsPlayCardRequestInProgress()
    return isPlayCardRequestInProgress
end

function _DiceAnimation(id, roll)
    if(racers:GetFromId(id).player ~= client.localPlayer) then
        return
    end
    local rotation = Vector3.new(0,0,0)
    local x, y, z = 0, 0, 0

    if (roll == 1) then
        x = 90
        y = 0
        z = 0
    elseif (roll == 2) then
        x = 180
        y = 0
        z = 0
    elseif (roll == 3) then
        x = 0
        y = -90
        z = 0
    elseif (roll == 4) then
        x = 0
        y = 90
        z = 0
    elseif (roll == 5) then
        x = 0
        y = 0
        z = 0
    elseif (roll == 6) then
        x = -90
        y = 0
        z = 0
    end

    -- Apply rotation to the cube
    rotation = Vector3.new(x,y,z)
    diceMesh.localEulerAngles = rotation
    diceAnimator:SetTrigger("Flip")
    audioManagerGameObject:GetComponent("AudioManager"):PlayDiceRoll()
end