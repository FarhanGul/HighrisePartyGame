--Enums
local Location={Lobby = 0 , Game = 1}

--Variables
--!SerializeField
local waitingForPlayerUI : GameObject = nil
local view
local location
local racers

function self:ClientAwake()
    view = self:GetComponent("RacerUIView")
end

function UpdateView()
    waitingForPlayerUI.SetActive(waitingForPlayerUI,location == Location.Lobby)
    for i=1,2 do
        if(location == Location.Lobby) then 
            view:GetComponent("RacerUIView").SetPlayer(i,nil)
        else
            view:GetComponent("RacerUIView").SetPlayer(i,racers:GetFromId(i))
        end
    end
end