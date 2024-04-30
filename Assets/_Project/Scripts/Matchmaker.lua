--Public Variables
--!SerializeField
local raceGame : GameObject = nil
--!SerializeField
local cameraRoot : GameObject = nil
--

--Private Variables
local maxMatches = 1
local waitingQueue={}
local matchTable
--

-- Events
local e_sendStartMatchToClients = Event.new("sendStartMatchToClients")
local e_sendMatchCancelledToClients = Event.new("sendMatchCancelledToClients")
local e_sendTeleportEventToClients = Event.new("sendTeleportEventToClients")
--

--Classes
function Match(_p1,_p2,_firstTurn)
    return{
        p1 = _p1,
        p2 = _p2,
        firstTurn = _firstTurn,
        GetId = function (self)
            return self.p1.id..self.p2.id
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
                if(v.p1 == player) then return v.p2 end
                if(v.p2 == player) then return v.p1 end
            end
            return nil
        end,
        Remove = function(self,player)
            for k,v in pairs(self._table) do
                if(v.p1 == player or v.p2 == player) then self._table[k] = nil return end
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
        -- Todo remove magic number
        Timer.new(2,function()
            table.insert(waitingQueue,player)
            while CreateMatch() do end
        end,false)
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

function CreateMatch()
    if(matchTable:GetCount() < maxMatches and #waitingQueue > 1)then
        local p1 = waitingQueue[1]
        local p2 = waitingQueue[2]
        table.remove(waitingQueue,1)
        table.remove(waitingQueue,1)
        local match = Match(p1,p2,math.random(1,2))
        matchTable:Add(match)
        -- print("new match id : "..tostring(match:GetId()))
        p1.character.transform.position = Vector3.new(100,0,0)
        p2.character.transform.position = Vector3.new(100,0,0)
        e_sendStartMatchToClients:FireAllClients(p1,p2,match.firstTurn)
        return true
    else
        return false
    end
end

function self:ClientAwake()
    e_sendStartMatchToClients:Connect(function(p1,p2,firstTurn)
        local match = Match(p1,p2,firstTurn)
        -- print("client recieve match players: "..tostring(match.p1.name)..tostring(match.p2.name))
        match.p1.character:Teleport(Vector3.new(100,0,0),function() print("p1 Teleported") end)
        match.p2.character:Teleport(Vector3.new(100,0,0),function() print("p2 Teleported") end)
        -- cameraRoot.transform.position = Vector3.new(100,0,0);
        cameraRoot:GetComponent("RTSCamera").CenterOn(Vector3.new(100,0,0))
        -- client.mainCamera.gameObject:SetActive(false)
        -- client.localPlayer.character.gameObject:SetActive(false)
        -- client.mainCamera.transform.position += Vector3.new(100,0,0)
        -- client.localPlayer.character.transform.position = Vector3.new(100,0,0)
        -- client.localPlayer.character.gameObject:SetActive(true)
        -- client.mainCamera.gameObject:SetActive(true)
        raceGame:GetComponent("RaceGame").StartMatch(match)
    end)
    e_sendMatchCancelledToClients:Connect(function(otherPlayer)
        if(client.localPlayer == otherPlayer) then raceGame:GetComponent("RaceGame"):GoToLobby() end
    end)
end