--Public Fields
--!SerializeField
local diceTapHandler : TapHandler = nil
--!SerializeField
local boardGameObject : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--

--Events
local e_sendRollToServer = Event.new("sendRollToServer")
local e_sendRollToClients = Event.new("sendRollToClients")
--

--Private Variables
local racers
local localRacer
local playerHud
--

--Classes
local function Racer(_id,_player,_isTurn)
    return {
        id = _id,
        player = _player,
        isTurn = _isTurn
    }
end

local function Racers()
    return {
        list = {},
        Add = function(self,racer)
            self.list[racer.player] = racer
        end,
        GetFromPlayer = function(self,player)
            return self.list[player]
        end,
        GetFromId = function (self,id)
            for k,v in pairs(self.list) do
                if(v.id == id) then
                    return v
                end
            end
            return nil
        end,
        GetCount = function(self)
            local c = 0
            for k,v in pairs(self.list) do
                c+=1
            end
            return c
        end,
        GetOtherId = function(id)
            if id == 1 then return 2 else return 1 end
        end
    }
end


function self:ClientAwake()
    playerHud = playerHudGameObject:GetComponent("PlayerHud")
end

function self:ServerAwake()
    e_sendRollToServer:Connect(function(player,id, roll)
        e_sendRollToClients:FireAllClients(id,roll)
    end)
end

function StartMatch(match)
    print("Start Match : "..match.p1.name.." vs "..match.p2.name)
    boardGameObject:GetComponent("Board").Reset()
    racers = Racers()
    racers:Add(Racer(1,match.p1,match.firstTurn == 1))
    racers:Add(Racer(2,match.p2,match.firstTurn == 2))
    playerHud.racers = racers
    localRacer = racers:GetFromPlayer(client.localPlayer)
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(localRacer.isTurn) then
            e_sendRollToServer:FireServer(localRacer.id ,math.random(1,6)) 
        end
    end)
    e_sendRollToClients:Connect(function(id, roll)
        boardGameObject:GetComponent("Board").Move(id,roll)
        racers:GetFromId(id).isTurn = false
        racers:GetFromId(racers.GetOtherId(id)).isTurn = true
        playerHud.UpdateView()
    end)
end

