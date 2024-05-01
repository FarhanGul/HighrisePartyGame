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
local welcome_title : UILabel = nil
--!Bind
local welcome_subtitle : UILabel = nil
--!Bind
local welcome_description : UILabel = nil
--!Bind
local welcome_guide : UILabel = nil
--!Bind
local welcome_play_button_text : UILabel = nil

--!Bind
local welcome_play_button : UIButton = nil

--Variables
local location
local racers
local OnWelcomeScreenClosed

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
    welcome_title:SetPrelocalizedText(strings.title, false)
    welcome_subtitle:SetPrelocalizedText("WELCOME", false)
    welcome_description:SetPrelocalizedText("A tabletop game where players compete in a high-stakes race. Along the way, you'll roll dice, play powerful cards, and unleash unique abilities. Gather your friends, grab your dice, and let's have some fun.", false)
    welcome_guide:SetPrelocalizedText("When it is your turn tap the dice to roll. Your piece will move automatically. Get to the finish spot before your opponent to win. Best of luck!", false)
    welcome_play_button_text:SetPrelocalizedText("PLAY", false)

    -- Register callback
    welcome_play_button:RegisterPressCallback(CloseWelcomeScreen)
end

function ShowWelcomeScreen(onClose)
    OnWelcomeScreenClosed = onClose
    welcome_group.visible = true
end

function CloseWelcomeScreen()
    print("Welcome Screen Closed")
    welcome_group.visible = false
    OnWelcomeScreenClosed()
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
end