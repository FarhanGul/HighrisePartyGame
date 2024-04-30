--Public Variables
--!SerializeField
local waitingArea : GameObject = nil
--!SerializeField
local raceGames : GameObject = nil
--!SerializeField
local cameraRoot : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--

--Private Variables
-- local maxMatches = 1
-- local waitingQueue={}
local matchTable
local gameInstances
local playerHud
--

-- Events
local e_sendStartMatchToClient = Event.new("sendStartMatchToClient")
local e_sendMatchCancelledToClient = Event.new("sendMatchCancelledToClient")
local e_sendMoveToWaitingAreaToClient = Event.new("sendMoveToWaitingAreaToClient")
--

--Classes
function GameInstance(_raceGame,_p1,_p2,_firstTurn)
    return{
        raceGame = _raceGame,
        firstTurn = _firstTurn,
        p1 = _p1,
        p2 = _p2
    }
end

function GameInstances()
    return{
        _table = {},
        playersInWaitingQueue = {},
        Initialize = function(self)
            for i=0, raceGames.transform.childCount - 1 do
                table.insert(self._table,GameInstance(raceGames.transform:GetChild(i).gameObject:GetComponent("RaceGame"),nil,nil,nil))
            end
        end,
        GetOtherPlayer = function(self,player)
            for k,v in pairs(self._table) do
                if(v.p1 ~= nil and v.p2 ~= nil) then
                    if (v.p1 == player ) then return v.p2
                    elseif(v.p2 == player) then return v.p1
                    end
                end
            end
            return nil
        end,
        HandlePlayerSlotsFreed = function(self,count)
            -- Handle players in waiting queue as new players based on free slots
            for i=1,count do
                if(#self.playersInWaitingQueue > 0) then
                    self.HandleNewPlayer(self.playersInWaitingQueue[1])
                    table.remove(self.playersInWaitingQueue,1)
                end
            end
        end,
        HandlePlayerLeft = function(self,player)
            -- Is player in waiting area then remove from waiting area
            local indexOfPlayerInWaitingQueue = table.find(self.playersInWaitingQueue, player)
            if(indexOfPlayerInWaitingQueue ~= nil) then
                table.remove(self.playersInWaitingQueue,indexOfPlayerInWaitingQueue)
                return
            end
            -- Is player in game instance table waiting for another player then remove from there
            for k,v in pairs(self._table) do
                if (v.p1 == player and v.p2 == nil ) then
                    v.p1 = nil
                    self.HandlePlayerSlotsFreed(1)
                    return
                end
            end
            -- if player was inside game when they left, notify other player and handle them like new player
            for k,v in pairs(self._table) do
                if(v.p1 ~= nil and v.p2 ~= nil) then
                    if ( v.p1 == player or v.p2 == player ) then
                        local otherPlayer = self.GetOtherPlayer()
                        e_sendMatchCancelledToClient:FireAllClients(otherPlayer)
                        self.HandleNewPlayer(otherPlayer)
                        v.p1 = nil
                        v.p2 = nil
                        self.HandlePlayerSlotsFreed(2)
                        return
                    end
                end
            end

        end,
        HandleNewPlayer = function(self,player)
            -- if another player is waiting then create match
            -- then send both players to game area
            for k,v in pairs(self._table) do
                if (v.p1 ~= nil ) then
                    v.p2 = player
                    v.firstTurn = math.random(1,2)
                    v.p1.character.transform.position = v.raceGame.transform.position
                    v.p2.character.transform.position = v.raceGame.transform.position
                    e_sendStartMatchToClient:FireAllClients(v.p1,v.raceGame,v.p1,v.p2,v.firstTurn)
                    e_sendStartMatchToClient:FireAllClients(v.p2,v.raceGame,v.p1,v.p2,v.firstTurn)
                    return
                end
            end
            -- If no players are waiting then see if there is a free instance this player can be assigned to
            -- then send player to waiting area
            for k,v in pairs(self._table) do
                if (v.p1 == nil and v.p2 == nil ) then 
                    v.p1 = player
                    v.p1.character.transform.position = waitingArea.transform.position
                    e_sendMoveToWaitingAreaToClient:FireAllClients(v.p1)
                    return
                end
            end
            -- We are out of game instances
            -- add player to waiting queue and send player to waiting area
            player.character.transform.position = waitingArea.transform.position
            e_sendMoveToWaitingAreaToClient:FireAllClients(player)
            table.insert(self.playersInWaitingQueue,player)
        end
    }
end

function self:ServerAwake()
    print("Server"..tostring(raceGames==nil))
    gameInstances = GameInstances()
    gameInstances:Initialize()
    server.PlayerConnected:Connect(function(player)
        -- Todo remove magic number delay
        Timer.new(2,function() gameInstances:HandleNewPlayer(player) end,false)
    end)

    server.PlayerDisconnected:Connect(function(player)
        gameInstances:HandlePlayerLeft(player)
    end)
end

function self:ClientAwake()
    print("Client"..tostring(raceGames==nil))
    playerHud = playerHudGameObject:GetComponent("PlayerHud")

    e_sendStartMatchToClient:Connect(function(player,raceGame,p1,p2,firstTurn)
        if(client.localPlayer == player)then
            local instance = GameInstance(raceGame,p1,p2,firstTurn)
            instance.p1.character:Teleport(instance.raceGame.transform.position,function() end)
            instance.p2.character:Teleport(instance.raceGame.transform.position,function() end)
            cameraRoot:GetComponent("RTSCamera").CenterOn(instance.raceGame.transform.position)
            instance.raceGame:GetComponent("RaceGame").StartMatch(instance)
            playerHud.location = playerHud.Location.Game
            playerHud.UpdateView()
        end
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function(player)
        if(client.localPlayer == player) then 
            playerHud.location = playerHud.Location.Lobby
            playerHud.UpdateView()
            player.character:Teleport(waitingArea.transform.position,function() end)
            cameraRoot:GetComponent("RTSCamera").CenterOn(waitingArea.transform.position) 
        end
    end)
    e_sendMatchCancelledToClient:Connect(function(player)
        if(client.localPlayer == player) then 
            print("Other Player Left the match : Show message on HUD")
        end
    end)
end