--!Type(UI)

--Constants
local strings={
    title = "TABLETOP RACER"
}

--!SerializeField
local allowDebugInput : boolean = false

--!Bind
local root: VisualElement = nil

--Variables
local location
local racers
local OnWelcomeScreenClosed
local OnResultScreenClosed
local OnOpponentLeftScreenClosed

--Enums
function Location ()
    return {Lobby = 0 , Game = 1}
end

function self:ClientAwake()
    Initialize()
end

function self:ClientUpdate()
    if(allowDebugInput) then HandleDebugInput() end
end

function SetLocation(_location)
    location = _location
end

function SetRacers(_racers)
    racers = _racers
end

function UpdateView()
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
    root:Q("welcome_play_button_text"):SetPrelocalizedText("PLAY", false)

    root:Q("result_title"):SetPrelocalizedText(strings.title, false)
    root:Q("result_subtitle"):SetPrelocalizedText("GAME FINISHED", false)
    root:Q("result_play_button_text"):SetPrelocalizedText("PLAY AGAIN", false)
    
    root:Q("opponent_left_title"):SetPrelocalizedText(strings.title, false)
    root:Q("opponent_left_subtitle"):SetPrelocalizedText("OPPONENT LEFT THE MATCH", false)
    root:Q("opponent_left_play_button_text"):SetPrelocalizedText("PLAY AGAIN", false)
    
    root:Q("vs_label"):SetPrelocalizedText("vs", false)

    -- Register callbacks
    root:Q("welcome_play_button"):RegisterPressCallback(CloseWelcomeScreen)
    root:Q("result_play_button"):RegisterPressCallback(function()CloseResult(true)end)
    root:Q("opponent_left_play_button"):RegisterPressCallback(function()CloseOpponentLeft(true)end)

    -- Set Intial State
    CloseResult(false)
    CloseOpponentLeft(false)
end

function ShowWelcomeScreen(onClose)
    OnWelcomeScreenClosed = onClose
    root:Q("welcome_group").visible = true
end

function CloseWelcomeScreen()
    root:Q("welcome_group").visible = false
    OnWelcomeScreenClosed()
end

function ShowResult(didWin,onClose)
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
    OnOpponentLeftScreenClosed = onClose
    root:Q("opponent_left_group").visible = true
end

function CloseOpponentLeft(invokeCallback)
    if(invokeCallback) then OnOpponentLeftScreenClosed() end
    root:Q("opponent_left_group").visible = false
end

function SetPlayer(id,racer)
    if (racer == nil) then
        root:Q("username_"..id).visible = false
        root:Q("turn_indicator_"..id):AddToClassList("hide")
        root:Q("vs_label").visible = false
        return
    end
    root:Q("username_"..id).visible = true
    root:Q("vs_label").visible = true
    root:Q("username_"..id):SetPrelocalizedText(racer.player.name, false)
    if(racer.isTurn) then root:Q("turn_indicator_"..id):RemoveFromClassList("hide") else root:Q("turn_indicator_"..id):AddToClassList("hide") end
end

function SetSceneHeading(title,subtitle)
    if (title == nil or subtitle == nil) then
        root:Q("scene_heading_group").visible = false
        return
    end
    root:Q("scene_heading_group").visible = true
    root:Q("scene_title"):SetPrelocalizedText(title, false)
    root:Q("scene_subtitle"):SetPrelocalizedText(subtitle, false)
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
    if(root:Q("welcome_group").visible and Input.isAltPressed) then CloseWelcomeScreen() end
    if(root:Q("result_group").visible and Input.isAltPressed) then CloseResult(true) end
end