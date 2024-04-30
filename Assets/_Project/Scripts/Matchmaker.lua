--Public Variables
--!SerializeField
local raceGame : GameObject = nil
--

--Private Variables
local maxMatches = 1
local waitingQueue={}
local matchTable
--

-- Events
local e_sendStartMatchToClients = Event.new("sendStartMatchToClients")
local e_sendMatchCancelledToClients = Event.new("sendMatchCancelledToClients")
--

--Classes
function Match(_player_01,_player_02)
    return{
        player_01 = _player_01,
        player_02 = _player_02,
        GetId = function (self)
            return self.player_01.id..self.player_02.id
        end
    }
end

function MatchTable()
    return{
        _table = {},
        Add = function(self,match)
            table[match:GetId()] = match
        end,
        GetOtherPlayer = function(self,player)
            for k,v in pairs(self._table) do
                if(v.player_01 == player) then return v.player_02 end
                if(v.player_02 == player) then return v.player_01 end
            end
            return nil
        end,
        Remove = function(self,player)
            for k,v in pairs(self._table) do
                if(v.player_01 == player or v.player_02 == player) then self._table[k] = nil return end
            end
        end,
        GetCount = function(self)
            local c = 0
            for k,v in pairs(self._table) do
                    c+=1
            end
            return c
        end
    }
end
--

function self:ServerAwake()
    matchTable = MatchTable()
    server.PlayerConnected:Connect(function(player)
        table.insert(waitingQueue,player)
        while CheckMatch() do end
    end)

    server.PlayerDisconnected:Connect(function(player)
        local waitingQueueRef = table.find(waitingQueue, player)
        local otherPlayer = matchTable:GetOtherPlayer(player)
        if (waitingQueueRef ~= nil) then table.remove(waitingQueue,waitingQueueRef) 
        elseif (otherPlayer ~= nil ) then 
            e_sendMatchCancelledToClients:FireAllClients(otherPlayer) 
            matchTable:Remove(otherPlayer)
        end
    end)
end

function CheckMatch()
    if(matchTable:GetCount() < maxMatches and #waitingQueue > 1)then
        local p1 = waitingQueue[1]
        local p2 = waitingQueue[2]
        table.remove(waitingQueue,1)
        table.remove(waitingQueue,1)
        local newMatch = Match(p1,p2)
        matchTable:Add(newMatch)
        print("new match id : "..tostring(newMatch:GetId()))
        e_sendStartMatchToClients:FireAllClients(p1,p2)
        return true
    else
        return false
    end
end

function self:ClientAwake()
    e_sendStartMatchToClients:Connect(function(p1,p2)
        print("client recieve match players: "..tostring(p1.name)..tostring(p2.name))
        raceGame:GetComponent("RaceGame").StartMatch(p1,p2)
    end)
    e_sendMatchCancelledToClients:Connect(function(otherPlayer)
        if(client.localPlayer == otherPlayer) then raceGame:GetComponent("RaceGame"):GoToLobby() end
    end)
end