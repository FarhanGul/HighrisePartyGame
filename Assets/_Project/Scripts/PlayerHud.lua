--Enums
function Location ()
    return {Lobby = 0 , Game = 1}
end

--Variables
--!SerializeField
local waitingForPlayerUI : GameObject = nil
local view
local location
local racers

function self:ClientAwake()
    view = self:GetComponent("RacerUIView")
end

function SetLocation(_location)
    location = _location
end

function SetRacers(_racers)
    racers = _racers
end

function UpdateView()
    waitingForPlayerUI.SetActive(waitingForPlayerUI,location == Location().Lobby)
    for i=1,2 do
        if(location == Location().Lobby) then 
            view:GetComponent("RacerUIView").SetPlayer(i,nil)
        else
            view:GetComponent("RacerUIView").SetPlayer(i,racers:GetFromId(i))
        end
    end
end