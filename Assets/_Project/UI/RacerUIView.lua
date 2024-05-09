--!Type(UI)

--Constants
local strings={
    title = "COSMIC RUSH",
    totalLaps = "3"
}

--!SerializeField
local uiDebugMode : boolean = false
-- --!SerializeField
-- local allowDebugInput : boolean = false
--!SerializeField
local playTapHandler : TapHandler = nil

--!Bind
local root: VisualElement = nil

--Variables
local location
local racers
local OnWelcomeScreenClosed
local OnResultScreenClosed
local OnOpponentLeftScreenClosed
local uiDebugCycleIndex = 0
local isAltReleased

--Enums
function Location ()
    return {Lobby = 0 , Game = 1}
end

function self:ClientAwake()
    Initialize()
    playTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(root:Q("welcome_group").visible) then
            CloseWelcomeScreen()
        elseif(root:Q("result_group").visible) then
            CloseResult(true)
        elseif(root:Q("opponent_left_group").visible) then
            CloseOpponentLeft(true)
        end
        playTapHandler.gameObject:SetActive(false)
    end)
end

function self:ClientUpdate()
    -- if(allowDebugInput) then HandleDebugInput() end
    if(uiDebugMode) then HandleUiDebug() end
end

function SetLocation(_location)
    location = _location
end

function SetRacers(_racers)
    racers = _racers
end

function UpdateView()
    ShowSceneView()
    if (location == Location().Lobby) then SetSceneHeading(strings.title,"WAITING AREA") else SetSceneHeading(strings.title,"GAME") end
    if (location == Location().Lobby) then SetSceneHelp("PLEASE WAIT FOR MATCH") else
        if(racers.IsLocalRacerTurn()) then SetSceneHelp("IT IS YOUR TURN") else SetSceneHelp("PLEASE WAIT FOR YOUR OPPONENET'S TURN") end
    end
    for i=1,2 do
        if(location == Location().Lobby) then
            SetPlayer(i,nil)
        else
            SetPlayer(i,racers:GetFromId(i))
        end
    end
end

function Initialize()
    -- Set Text
    root:Q("welcome_title"):SetPrelocalizedText(strings.title, false)
    root:Q("welcome_subtitle"):SetPrelocalizedText("WELCOME", false)
    root:Q("welcome_description"):SetPrelocalizedText("A tabletop game where players compete in a high-stakes race. Along the way, you'll roll dice, play powerful cards, and unleash unique abilities. Gather your friends, grab your dice, and let's have some fun.", false)
    root:Q("welcome_guide"):SetPrelocalizedText("When it is your turn tap the dice to roll. Your piece will move automatically. Get to the finish spot before your opponent to win. Best of luck!", false)

    root:Q("result_title"):SetPrelocalizedText(strings.title, false)
    root:Q("result_subtitle"):SetPrelocalizedText("GAME FINISHED", false)

    root:Q("opponent_left_title"):SetPrelocalizedText(strings.title, false)
    root:Q("opponent_left_subtitle"):SetPrelocalizedText("OPPONENT LEFT THE MATCH", false)

    root:Q("vs_label"):SetPrelocalizedText("vs", false)

    -- Set Intial State
    CloseResult(false)
    CloseOpponentLeft(false)
    CloseSceneView()
end

function ShowSceneView()
    root:Q("scene_heading_group").visible = true
    root:Q("scene_help_group").visible = true
    root:Q("username_group"):EnableInClassList("hide",false)
end

function CloseSceneView()
    root:Q("scene_heading_group").visible = false
    root:Q("scene_help_group").visible = false
    root:Q("username_group"):EnableInClassList("hide",true)
end

function ShowWelcomeScreen(onClose)
    CloseSceneView()
    playTapHandler.gameObject:SetActive(true)
    OnWelcomeScreenClosed = onClose
    root:Q("welcome_group").visible = true
end

function CloseWelcomeScreen()
    root:Q("welcome_group").visible = false
    OnWelcomeScreenClosed()
end

function ShowResult(didWin,onClose)
    CloseSceneView()
    playTapHandler.gameObject:SetActive(true)
    OnResultScreenClosed = onClose
    root:Q("result_group").visible = true
    if(didWin) then
        root:Q("result_win_image"):RemoveFromClassList("hide")
        root:Q("result_lose_image"):AddToClassList("hide")
    else
        root:Q("result_win_image"):AddToClassList("hide")
        root:Q("result_lose_image"):RemoveFromClassList("hide")
    end
end

function CloseResult(invokeCallback)
    if(invokeCallback) then OnResultScreenClosed() end
    root:Q("result_group").visible = false
    root:Q("result_win_image"):AddToClassList("hide")
    root:Q("result_lose_image"):AddToClassList("hide")
end

function ShowOpponentLeft(onClose)
    CloseSceneView()
    playTapHandler.gameObject:SetActive(true)
    OnOpponentLeftScreenClosed = onClose
    root:Q("opponent_left_group").visible = true
end

function CloseOpponentLeft(invokeCallback)
    if(invokeCallback) then OnOpponentLeftScreenClosed() end
    root:Q("opponent_left_group").visible = false
end

function SetPlayer(id,racer)
    if (racer == nil) then
        root:Q("username_and_lap_"..id).visible = false
        -- root:Q("turn_indicator_"..id):AddToClassList("hide")
        root:Q("turn_indicator_"..id).visible = false
        root:Q("vs_label").visible = false
        return
    end
    root:Q("username_and_lap_"..id).visible = true
    root:Q("vs_label").visible = true
    -- if(racer.isTurn) then root:Q("turn_indicator_"..id):RemoveFromClassList("hide") else root:Q("turn_indicator_"..id):AddToClassList("hide") end
    root:Q("turn_indicator_"..id).visible = racer.isTurn

    root:Q("username_"..id):SetPrelocalizedText(racer.player.name, false)
    root:Q("lap_"..id):SetPrelocalizedText(racer.lap.." / "..strings.totalLaps, false)

end

function SetSceneHeading(title,subtitle)
    if (title == nil or subtitle == nil) then
        root:Q("scene_heading_group").visible = false
        return
    end
    root:Q("scene_heading_group").visible = true
    root:Q("scene_title"):SetPrelocalizedText(title, false)
end

function SetSceneHelp(help)
    if (help == nil) then
        root:Q("scene_help_group").visible = false
        return
    end
    root:Q("scene_help_group").visible = true
    root:Q("scene_help"):SetPrelocalizedText(help, false)
end

function HandleDebugInput()
    -- if(root:Q("welcome_group").visible and Input.isAltPressed) then CloseWelcomeScreen() end
    -- if(root:Q("result_group").visible and Input.isAltPressed) then CloseResult(true) end
end

function HandleUiDebug()
    if(not isAltReleased and not Input.isAltPressed) then
        isAltReleased = true
    end
    if(isAltReleased and Input.isAltPressed) then
        isAltReleased = false
        if(uiDebugCycleIndex == 0) then
            CloseResult(false)
            ShowWelcomeScreen(function()end)
        elseif(uiDebugCycleIndex == 1) then
            CloseWelcomeScreen()
            SetLocation(Location().Lobby)
            UpdateView()
        elseif(uiDebugCycleIndex == 2) then
            SetSceneHeading(strings.title,"GAME")
            SetSceneHelp("PLEASE WAIT FOR YOUR OPPONENET'S TURN")
            local debugRacer = {}
            debugRacer.lap = 1
            debugRacer.isTurn = true
            debugRacer.player = {}
            debugRacer.player.name = "Debug Racer big name 01"
            SetPlayer(1,debugRacer)
            debugRacer.isTurn = false
            debugRacer.player.name = "sn"
            SetPlayer(2,debugRacer)
        elseif(uiDebugCycleIndex == 3) then
            ShowOpponentLeft(function()end)
        elseif(uiDebugCycleIndex == 4) then
            CloseOpponentLeft(false)
            ShowResult(function()end, nil)
        end
        uiDebugCycleIndex += 1
        if(uiDebugCycleIndex == 5) then uiDebugCycleIndex = 0 end
    end
end