--!Type(UI)

--Constants
local strings={
    title = "COSMIC RUSH",
    totalLaps = "3"
}

--!SerializeField
local playTapHandler : TapHandler = nil
--!SerializeField
local playPressedGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local player01Hud : GameObject = nil
--!SerializeField
local player02Hud : GameObject = nil
--!SerializeField
local turnGenericTextGameObject : GameObject = nil
--!SerializeField
local actionMessageGenericTextGameObject : GameObject = nil
--!SerializeField
local actionHelpGenericTextGameObject : GameObject = nil

--!Bind
local root: VisualElement = nil

--Variables
local location
local racers
local board
local OnWelcomeScreenClosed
local OnResultScreenClosed
local OnOpponentLeftScreenClosed
local uiDebugCycleIndex = 0
local isAltReleased
local action

--Enums
function Location ()
    return {Lobby = 0 , Game = 1}
end

function self:ClientAwake()
    Initialize()
    -- playTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
    --     if(root:Q("welcome_group").visible) then
    --         CloseWelcomeScreen()
    --     elseif(root:Q("result_group").visible) then
    --         CloseResult()
    --     elseif(root:Q("opponent_left_group").visible) then
    --         CloseOpponentLeft()
    --     end
    --     SetPlayMatchButton(false)
    --     audioManagerGameObject:GetComponent("AudioManager"):PlayClick()
    -- end)
end

function SetBoard(_board)
    board = _board
end

function SetLocation(_location)
    location = _location
end

function SetRacers(_racers)
    racers = _racers
end

function UpdateAction(_action)
    action = _action
    UpdateGameView()
end

function UpdateGameView()
    if(racers.IsLocalRacerTurn()) then 
        root:Q("game_help"):SetPrelocalizedText("IT'S YOUR TURN", false)
    else 
        root:Q("game_help"):SetPrelocalizedText("IT'S YOUR OPPONENT'S TURN", false)
    end

    for i=1,2 do
        if(location == Location().Lobby) then
            SetPlayer(i,nil)
        else
            local data = racers:GetFromId(i)
            data.health = board.GetHealth()[i]
            data.cardCount = board.GetCardManager().GetCardCount(racers:GetFromId(i).player)
            SetPlayer(i,data)
        end
    end

    if(action ~= nil) then 
        root:Q("action_player"):SetPrelocalizedText(action.player, false)
        root:Q("action_text"):SetPrelocalizedText(action.text, false)
    else
        root:Q("action_player"):SetPrelocalizedText("Match started", false)
        root:Q("action_text"):SetPrelocalizedText("May the odds be in your favor", false)
    end

    SetActionAndTurn(action,racers.IsLocalRacerTurn())
end

function Initialize()
    -- Set Text
    root:Q("welcome_title"):SetPrelocalizedText(strings.title, false)
    root:Q("welcome_subtitle"):SetPrelocalizedText("WELCOME", false)
    root:Q("welcome_description"):SetPrelocalizedText("A tabletop race where you'll roll dice and play cards. Get to the finish spot before your opponent or destroy the opponent alien to win. Best of luck!", false)
    root:Q("welcome_guide"):SetPrelocalizedText("Roll the dice to move your piece. If you have cards, tap the card to select it and play it before your dice roll, tap the card to select it", false)

    root:Q("result_title"):SetPrelocalizedText(strings.title, false)
    root:Q("result_subtitle"):SetPrelocalizedText("GAME FINISHED", false)

    root:Q("opponent_left_title"):SetPrelocalizedText(strings.title, false)
    root:Q("opponent_left_subtitle"):SetPrelocalizedText("OPPONENT LEFT THE MATCH", false)

    root:Q("lap_label_1"):SetPrelocalizedText("Lap", false)
    root:Q("lap_label_2"):SetPrelocalizedText("Lap", false)
    root:Q("overclock_label_1"):SetPrelocalizedText("Health", false)
    root:Q("overclock_label_2"):SetPrelocalizedText("Health", false)
    root:Q("card_count_label_1"):SetPrelocalizedText("Cards", false)
    root:Q("card_count_label_2"):SetPrelocalizedText("Cards", false)
    
    root:Q("waiting_title"):SetPrelocalizedText(strings.title, false)
    root:Q("waiting_help"):SetPrelocalizedText("PLEASE WAIT FOR MATCH", false)
    root:Q("game_title"):SetPrelocalizedText(strings.title, false)

    -- Set Intial State
    root:Q("waiting_for_match_group").visible = false
    root:Q("game_view_group").visible = false
    root:Q("result_group").visible = false
    root:Q("opponent_left_group").visible = false
end

function SetPlayMatchButton(isActive)
    -- playTapHandler.gameObject:SetActive(isActive)
    -- playPressedGameObject:SetActive(not isActive)
end

function ShowWelcomeScreen(onClose)
    SetPlayMatchButton(true)
    OnWelcomeScreenClosed = onClose
    root:Q("welcome_group").visible = true
end

function CloseWelcomeScreen()
    root:Q("welcome_group").visible = false
    OnWelcomeScreenClosed()
    ShowWaitingForMatch()
end

function ShowWaitingForMatch()
    root:Q("waiting_for_match_group").visible = true
end

function CloseWaitingForMatch()
    root:Q("waiting_for_match_group").visible = false
end

function ShowGameView()
    UpdateAction(nil)
    CloseWaitingForMatch()
    root:Q("game_view_group").visible = true
end

function CloseGameView()
    root:Q("game_view_group").visible = false
end

function ShowResult(didWin,onClose)
    CloseGameView()
    SetPlayMatchButton(true)
    OnResultScreenClosed = onClose
    root:Q("result_group").visible = true
    root:Q("result_win_image"):EnableInClassList("hide", not didWin)
    root:Q("result_lose_image"):EnableInClassList("hide",didWin)

end

function CloseResult()
    OnResultScreenClosed()
    ShowWaitingForMatch()
    root:Q("result_group").visible = false
    root:Q("result_win_image"):EnableInClassList("hide",true)
    root:Q("result_lose_image"):EnableInClassList("hide",true)
end

function IsResultShowing()
    return root:Q("result_group").visible
end

function ShowOpponentLeft(onClose)
    CloseGameView()
    audioManagerGameObject:GetComponent("AudioManager"):PlayDisconnect()
    SetPlayMatchButton(true)
    OnOpponentLeftScreenClosed = onClose
    root:Q("opponent_left_group").visible = true
end

function CloseOpponentLeft()
    ShowWaitingForMatch()
    OnOpponentLeftScreenClosed()
    root:Q("opponent_left_group").visible = false
end

function SetPlayer(id,data)
    if (data == nil) then
        return
    end
    root:Q("username_"..id):SetPrelocalizedText(data.player.name, false)
    root:Q("lap_"..id):SetPrelocalizedText(data.lap.." / "..strings.totalLaps, false)
    root:Q("overclock_"..id):SetPrelocalizedText(data.health, false)
    root:Q("card_count_"..id):SetPrelocalizedText(data.cardCount.." / 3", false)

    -- New UI
    local hud = id == 1 and player01Hud or player02Hud
    hud.transform:Find("NameGenericText").gameObject:GetComponent("GenericText").SetText(data.player.name)
    hud.transform:Find("LapGenericText").gameObject:GetComponent("GenericText").SetText(data.lap.." / "..strings.totalLaps)
    local healthRoot = hud.transform:Find("Health")
    for i = 0 , healthRoot.childCount -1 do
        healthRoot:GetChild(i).gameObject:SetActive(data.health > i)
    end
    local cardRoot = hud.transform:Find("CardCount")
    for i = 0 , cardRoot.childCount -1 do
        cardRoot:GetChild(i).gameObject:SetActive(data.cardCount > i)
    end

end

function SetActionAndTurn(action,isTurn)
    if(action ~= nil) then 
        actionMessageGenericTextGameObject:GetComponent("GenericText").SetText(action.player.." "..action.text)
        actionHelpGenericTextGameObject:GetComponent("GenericText").SetText(action.help)
    else
        actionMessageGenericTextGameObject:GetComponent("GenericText").SetText("Match started")
        actionHelpGenericTextGameObject:GetComponent("GenericText").SetText("May the odds be in your favor")
    end

    if(isTurn) then 
        turnGenericTextGameObject:GetComponent("GenericText").SetText("IT'S YOUR TURN")
    else 
        turnGenericTextGameObject:GetComponent("GenericText").SetText("IT'S YOUR OPPONENET'S TURN")
    end
end