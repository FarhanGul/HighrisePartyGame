--!Type(UI)

--Constants
local strings={
    title = "TABLETOP RACER"
}

--!SerializeField
local allowDebugInput : boolean = false

--!Bind
local usernames: VisualElement = nil
--!Bind
local scene_heading_group: VisualElement = nil
--!Bind
local scene_help_group: VisualElement = nil
--!Bind
local welcome_group: VisualElement = nil
--!Bind
local result_group: VisualElement = nil

--!Bind
local welcome_play_button : UIButton = nil
--!Bind
local result_play_button : UIButton = nil

--Variables
local location
local racers
local OnWelcomeScreenClosed
local OnResultScreenClosed

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
        if(racers.IsLocalRacerTurn()) then SetSceneHelp("IT IS YOUR TURN") else SetSceneHelp("PLEASE WAIT WHILE YOUR OPPONENET MAKES THEIR TURN") end
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
    welcome_group:Q("welcome_title"):SetPrelocalizedText(strings.title, false)
    welcome_group:Q("welcome_subtitle"):SetPrelocalizedText("WELCOME", false)
    welcome_group:Q("welcome_description"):SetPrelocalizedText("A tabletop game where players compete in a high-stakes race. Along the way, you'll roll dice, play powerful cards, and unleash unique abilities. Gather your friends, grab your dice, and let's have some fun.", false)
    welcome_group:Q("welcome_guide"):SetPrelocalizedText("When it is your turn tap the dice to roll. Your piece will move automatically. Get to the finish spot before your opponent to win. Best of luck!", false)
    welcome_group:Q("welcome_play_button_text"):SetPrelocalizedText("PLAY", false)

    result_group:Q("result_title"):SetPrelocalizedText(strings.title, false)
    result_group:Q("result_subtitle"):SetPrelocalizedText("GAME FINISHED", false)
    result_group:Q("result_play_button_text"):SetPrelocalizedText("PLAY AGAIN", false)

    -- Register callbacks
    welcome_play_button:RegisterPressCallback(CloseWelcomeScreen)
    result_play_button:RegisterPressCallback(function()CloseResult(true)end)

    -- Set Intial State
    CloseResult(false)
end

function ShowWelcomeScreen(onClose)
    OnWelcomeScreenClosed = onClose
    welcome_group.visible = true
end

function CloseWelcomeScreen()
    welcome_group.visible = false
    OnWelcomeScreenClosed()
end

function ShowResult(didWin,onClose)
    OnResultScreenClosed = onClose
    result_group.visible = true
    result_group:Q("result_win_image").visible = didWin
    result_group:Q("result_lose_image").visible = not didWin
end

function CloseResult(invokeCallback)
    if(invokeCallback) then OnResultScreenClosed() end
    result_group.visible = false
    result_group:Q("result_win_image").visible = false
    result_group:Q("result_lose_image").visible = false
end

function SetPlayer(id,racer)
    if (racer == nil) then
        usernames:Q("username_"..id).visible = false
        usernames:Q("turn_indicator_"..id).visible = false
        return
    end
    usernames:Q("username_"..id).visible = true
    usernames:Q("username_"..id):SetPrelocalizedText(racer.player.name, false)
    usernames:Q("turn_indicator_"..id).visible = racer.isTurn
end

function SetSceneHeading(title,subtitle)
    if (title == nil or subtitle == nil) then
        scene_heading_group.visible = false
        return
    end
    scene_heading_group.visible = true
    scene_heading_group:Q("scene_title"):SetPrelocalizedText(title, false)
    scene_heading_group:Q("scene_subtitle"):SetPrelocalizedText(subtitle, false)
end

function SetSceneHelp(help)
    if (help == nil) then
        scene_help_group.visible = false
        return
    end
    scene_help_group.visible = true
    scene_help_group:Q("scene_help"):SetPrelocalizedText(help, false)
end

function HandleDebugInput()
    if(welcome_group.visible and Input.isAltPressed) then CloseWelcomeScreen() end
    if(result_group.visible and Input.isAltPressed) then CloseResult(true) end
end