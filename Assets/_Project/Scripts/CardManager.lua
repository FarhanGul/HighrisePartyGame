local refs = require("References")
local common = require("Common")

-- Public
--!SerializeField
local debug : boolean = false
local diceAnimator : Animator = nil
local diceMesh : Transform = nil
local playCardTapHandler : TapHandler = nil
local rollTapHandler : TapHandler = nil
local rollPressed : GameObject = nil
local playCardPressed : GameObject = nil
local cardSlot_01 : TapHandler = nil
local cardSlot_02 : TapHandler = nil
local cardSlot_03 : TapHandler = nil
local emptyHandGenericTextGameObject : GameObject = nil

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
local debugPlayedCard = nil
local botRacer = nil

-- Events
local e_sendCardsToServer = Event.new("sendCardsToServer")
local e_sendCardsToClient = Event.new("sendCardsToClient")
local e_sendPlayCardToServer = Event.new("sendPlayCardToServer")
local e_sendPlayCardToClient = Event.new("sendPlayCardToClient")
local e_sendRollToServer = Event.new("sendRollToServer")
local e_sendRollToClients = Event.new("sendRollToClients")

function self:ServerAwake()
    e_sendCardsToServer:Connect(function(player,targetPlayer,_cards)
        e_sendCardsToClient:FireClient(targetPlayer,_cards)
    end)
    e_sendPlayCardToServer:Connect(function(player,targetPlayer,playerWhoPlayed,_playedCard)
        e_sendPlayCardToClient:FireClient(targetPlayer,playerWhoPlayed,_playedCard)
    end)
    e_sendRollToServer:Connect(function(player,targetPlayer,id, roll)
        e_sendRollToClients:FireClient(targetPlayer,id,roll)
    end)
end

function self:ClientAwake()
    SetReferences()
    if(debug) then
        print("Debug mode activated")
        Chat.TextMessageReceivedHandler:Connect(function(channel,from,message)
            local command = string.sub(message,1,1)
            local param = string.sub(message,3,-1)
            if(command == "d") then
                debugRoll = tonumber(param)
            elseif(command == "c") then
                debugPlayedCard = param
            elseif(command == "f") then
                board.SetLaps({3,3})
                racers:GetFromId(1).lap = 3
                racers:GetFromId(2).lap = 3
                refs.RacerUIView().UpdateGameView()
            end
            Chat:DisplayTextMessage(channel, from, message)
        end)
    end
    playCardTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(PlaySelectedCard)
    cardSlot_01.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(1) end)
    cardSlot_02.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(2) end)
    cardSlot_03.gameObject:GetComponent(TapHandler).Tapped:Connect(function() CardSlotClick(3) end)

    e_sendRollToClients:Connect(function(id, roll)
        HandleRoll(id, roll)
    end)

    e_sendPlayCardToClient:Connect(function(_player,_playedCard)
        HandlePlayedCard(_player,_playedCard)
    end)

    e_sendCardsToClient:Connect(function(_cards)
        cards = _cards
        OnCardCountUpdated()
    end)

    rollTapHandler.Tapped:Connect(function()
        if(racers.IsLocalRacerTurn() and not isRollRequestInProgress and not GetIsPlayCardRequestInProgress()) then
            isRollRequestInProgress = true
            didRoll = true
            SetInteractableState()
            HandleSyncedRoll(racers:GetRacerWhoseTurnItIs().id)
        end
    end)
end

function SetReferences()
    diceAnimator = self.transform:Find("Dice/Animator"):GetComponent(Animator)
    diceMesh = self.transform:Find("Dice/Animator/Mesh")
    playCardTapHandler = self.transform:Find("BoardCenter/PlayCardButton"):GetComponent(TapHandler)
    rollTapHandler = self.transform:Find("BoardCenter/RollButton"):GetComponent(TapHandler)
    rollPressed = self.transform:Find("BoardCenter/RollButtonPressed").gameObject
    playCardPressed = self.transform:Find("BoardCenter/PlayCardButtonPressed").gameObject
    cardSlot_01 = self.transform:Find("Cards/CardSlot_01"):GetComponent(TapHandler)
    cardSlot_02 = self.transform:Find("Cards/CardSlot_02"):GetComponent(TapHandler)
    cardSlot_03 = self.transform:Find("Cards/CardSlot_03"):GetComponent(TapHandler)
    emptyHandGenericTextGameObject = self.transform:Find("LabelEmptyHandGenericText").gameObject
end

function HandleSyncedRoll(id)
    local roll = math.random(1,6)
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendRollToServer:FireServer(remotePlayer,id,roll)
    end
    HandleRoll(id, roll)
end

function HandleRoll(id,roll)
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
end

function HandleCardAudio(_card)
    if(_card == "Zap") then
        refs.AudioManager().PlayZap()
    elseif(_card == "Nos") then
        refs.AudioManager().PlayNos()
    elseif(_card == "Honk") then
        refs.AudioManager().PlayHonk()
    elseif(_card == "WarpDrive") then
        refs.AudioManager().PlayNos()
    elseif(_card == "WormHole") then
        refs.AudioManager().PlayTeleport()
    elseif(_card == "ElectronBlaster") then
        refs.AudioManager().PlayZap()
        refs.AudioManager().PlayLaser()
    elseif(_card == "MeatHook") then
        refs.AudioManager().PlayHook()
    elseif(_card == "AntimatterCannon") then
        refs.AudioManager().PlayLaser()
    elseif(_card == "FlameThrower") then
        refs.AudioManager().PlayFlame()
    elseif(_card == "Regenerate") then
        refs.AudioManager().PlayUpgrade()
    end
end

function DiscardCards(_victim,count)
    if(#cards[_victim] > 0) then
        local cardsToDiscard = math.min(count,#cards[_victim])
        for i = 1 , cardsToDiscard do
            local randIndex = math.random(1, #cards[_victim])
            table.remove(cards[_victim],randIndex)
        end
        SetSyncedCards()
        OnCardCountUpdated()
    end
end

function SetSyncedCards()
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendCardsToServer:FireServer(remotePlayer,cards)
    end
end

function SetInteractableState()
    emptyHandGenericTextGameObject:GetComponent(MeshRenderer).enabled = #cards[client.localPlayer] == 0
    local status = refs.Matchmaker().GetMatchStatus() 
    if(status == "OpponentLeft" or status == "Finished")then
        rollPressed:SetActive(true)
        playCardPressed:SetActive(true)
        rollTapHandler.gameObject:SetActive(false)
        playCardTapHandler.gameObject:SetActive(false)
        return
    end
    local isLocalTurn = racers.IsLocalRacerTurn()
    rollPressed:SetActive(not isLocalTurn or (isLocalTurn and isRollRequestInProgress))
    playCardPressed:SetActive(not isLocalTurn or not CanPlaycard() or didRoll)
    rollTapHandler.gameObject:SetActive(isLocalTurn and not isRollRequestInProgress)
    playCardTapHandler.gameObject:SetActive(isLocalTurn and CanPlaycard() and not didRoll)
end


function OnCardCountUpdated()
    if(#cards[client.localPlayer] > 0) then selectedCard = #cards[client.localPlayer] else selectedCard = -1 end
    refs.RacerUIView().UpdateGameView()
    UpdateView()
end

function StealCards(thief,victim)
    if(client.localPlayer == thief and #cards[victim] > 0) then
        local randomIndex = math.random(1,#cards[victim])
        table.insert(cards[thief],cards[victim][randomIndex])
        table.remove(cards[victim],randomIndex)
        SetSyncedCards()
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
        {card="ElectronBlaster",probablity=0.5},
        {card="MeatHook",probablity=0.85},
        {card="AntimatterCannon",probablity=0.9},
        {card="FlameThrower",probablity=0.6},
        {card="Regenerate",probablity=1}
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
    local cardsToDraw = math.min(count,3 - #cards[racers:GetPlayerWhoseTurnItIs()])
    if(cardsToDraw > 0) then
        for i = 1, cardsToDraw do
            table.insert(cards[racers:GetPlayerWhoseTurnItIs()],GetRandomCard())
        end
        OnCardCountUpdated()
        SetSyncedCards()
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
    isPlayCardRequestInProgress = false
    isRollRequestInProgress = false
    debugRoll = nil
    debugPlayedCard = nil
    botRacer = _racers:GetBotRacer()
    OnCardCountUpdated()
    ExecuteBot()
end

function ExecuteBot()
    if (botRacer ~= nil and botRacer.isTurn and refs.Matchmaker().GetMatchStatus() == "InProgress") then
        -- Fetch Context
        local c = {
            botHealth = board.GetHealth()[botRacer.id],
            enemyHealth = board.GetHealth()[racers:GetOtherId(botRacer.id)],
            enemyCardCount = #cards[client.localPlayer],
            botLoc = board.GetLocation()[botRacer.id],
            enemyLoc = board.GetLocation()[racers:GetOtherId(botRacer.id)],
            cardsInHand = cards[botRacer.player],
            isEnemyOnSafeTile = board.IsOnSafeTile(racers:GetOtherId(botRacer.id))
        }

        -- Order cards by priority
        local priorityList = {"WormHole","ElectronBlaster","Regenerate","AntimatterCannon","WarpDrive","MeatHook","FlameThrower","Zap","Nos","Honk"}
        -- Adjust Damage and regeneration based on health
        -- Adjust Flamethrower based on opponent card count
        
        local _chosenCard = nil
        for i = 1, #priorityList do
            if(table.find(c.cardsInHand, priorityList[i])) then
                local _card = priorityList[i]
                if(_card == "WormHole") then
                    -- Only play if opponent is signifcantly ahead
                    local shouldPlay = c.enemyLoc > c.botLoc and math.abs(c.enemyLoc - c.botLoc) > math.random(14,20) and not c.isEnemyOnSafeTile
                    if(not shouldPlay) then continue end
                elseif(_card == "MeatHook") then
                    -- Only play if opponent has a card
                    local shouldPlay = c.enemyCardCount > 0 and not c.isEnemyOnSafeTile
                    if(not shouldPlay) then continue end
                elseif(_card == "ElectronBlaster") then
                    -- Only play if opponent is almost at end
                    local shouldPlay = c.enemyLoc > math.random(20,24) and not c.isEnemyOnSafeTile
                    if(not shouldPlay) then continue end
                elseif(_card == "Regenerate") then
                    -- Only play if damaged
                    local shouldPlay = c.botHealth < 4
                    if(not shouldPlay) then continue end
                elseif(_card == "FlameThrower") then
                    -- Only play if opponent has random 1-2 cards
                    local shouldPlay = c.enemyCardCount > math.random(1,2) and not c.isEnemyOnSafeTile
                    if(not shouldPlay) then continue end
                end
                _chosenCard = _card
            end
        end

        -- Do the executation with waits
        common.Coroutine(
            2,
            function() if(_chosenCard ~= nil) then HandlePlayedCard(botRacer.player,_chosenCard) end  end,
            _chosenCard == nil and 0 or 4,
            function() if( refs.Matchmaker().GetMatchStatus() == "InProgress" ) then HandleSyncedRoll(botRacer.id) end end
        )
    end
end

function TurnEnd()
    didRoll = false
    playedCard = nil
    debugPlayedCard = nil
    refs.RacerUIView().UpdateGameView()
    UpdateView()
    ExecuteBot()
end

function PlaySelectedCard()
    playedCard = cards[client.localPlayer][selectedCard]
    if(debugPlayedCard ~= nil ) then playedCard = debugPlayedCard end
    isPlayCardRequestInProgress = true
    SyncedHandlePlayedCard(playedCard)
end

function SyncedHandlePlayedCard(_playedCard)
    local remotePlayer = racers:GetOpponentPlayer(client.localPlayer)
    if(remotePlayer.isBot == nil) then
        e_sendPlayCardToServer:FireServer(remotePlayer,client.localPlayer,_playedCard)
    end
    HandlePlayedCard(client.localPlayer,_playedCard)
end

function HandlePlayedCard(_player,_playedCard)
    refs.AudioManager().PlayClick()
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
            DiscardCards(racers:GetOpponentPlayer(_player), 3)
        end
    end
    if(_playedCard == "Regenerate") then
        board.ChangeHealth(racers:GetFromPlayer(_player).id,1)
    end
    refs.RacerUIView().UpdateAction({
        player = _player.name,
        text  = "Played ".._playedCard..(isOpponentOnSafeTile and " but was blocked" or ""),
        help = GetCardHelp(_playedCard)
    })
    playedCard = _playedCard
    isPlayCardRequestInProgress = false
    OnCardCountUpdated()
end

function CardSlotClick(cardSlotIndex)
    if(CanPlaycard() and selectedCard ~= cardSlotIndex) then
        refs.AudioManager().PlayHit()
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
    refs.AudioManager().PlayDiceRoll()
end