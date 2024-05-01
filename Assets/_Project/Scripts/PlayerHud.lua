--Constants
local strings={
    title = "TABLETOP RACER"
}

--Enums
function Location ()
    return {Lobby = 0 , Game = 1}
end

--Variables
local view
local location
local racers

function self:ClientAwake()
    view = self:GetComponent("RacerUIView")
    view.Initialize(strings)
end

function SetLocation(_location)
    location = _location
end

function SetRacers(_racers)
    racers = _racers
end

function UpdateView()
    if (location == Location().Lobby) then view.SetSceneHeading(strings.title,"WAITING AREA") else view.SetSceneHeading(strings.title,"GAME") end
    if (location == Location().Lobby) then view.SetSceneHelp("PLEASE WAIT FOR MATCH") else 
        if(racers.IsLocalRacerTurn()) then view.SetSceneHelp("IT IS YOUR TURN") else view.SetSceneHelp("PLEASE WAIT WHILE YOUR OPPONENET MAKES THEIR TURN") end
    end
    for i=1,2 do
        if(location == Location().Lobby) then 
            view.SetPlayer(i,nil)
        else
            view.SetPlayer(i,racers:GetFromId(i))
        end
    end
end