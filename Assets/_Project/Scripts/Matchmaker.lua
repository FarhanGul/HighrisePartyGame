local gamesInfo = {
    count = 2,
    positions = {
        Vector3.new(100,0,0),
        Vector3.new(100,0,100),
    },
    waitingAreaPosition = Vector3.new(0,0,0)
}

--Public Variables
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
function GameInstance(_gameIndex,_p1,_p2,_firstTurn)
    return{
        gameIndex = _gameIndex,
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
            for i=1, gamesInfo.count do
                table.insert(self._table,GameInstance(i,nil,nil,nil))
            end
        end,
        HandlePlayerSlotsFreed = function(self,count)
            -- Handle players in waiting queue as new players based on free slots
            for i=1,count do
                if(#self.playersInWaitingQueue > 0) then
                    self:HandleNewPlayer(self.playersInWaitingQueue[1])
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
                    self:HandlePlayerSlotsFreed(1)
                    return
                end
            end
            -- if player was inside game when they left, notify other player and handle them like new player
            for k,v in pairs(self._table) do
                if(v.p1 ~= nil and v.p2 ~= nil) then
                    if ( v.p1 == player or v.p2 == player ) then
                        local otherPlayer
                        if (v.p1 == player) then otherPlayer = v.p2 else otherPlayer = v.p1 end
                        v.p1 = nil
                        v.p2 = nil
                        e_sendMatchCancelledToClient:FireAllClients(otherPlayer)
                        self:HandleNewPlayer(otherPlayer)
                        self:HandlePlayerSlotsFreed(1)
                        return
                    end
                end
            end

        end,
        HandleNewPlayer = function(self,player)
            -- if another player is waiting then create match
            -- then send both players to game area
            for k,v in pairs(self._table) do
                if (v.p1 ~= nil and v.p2 == nil  ) then
                    v.p2 = player
                    v.firstTurn = math.random(1,2)
                    v.p1.character.transform.position = gamesInfo.positions[v.gameIndex]
                    v.p2.character.transform.position = gamesInfo.positions[v.gameIndex]
                    e_sendStartMatchToClient:FireAllClients(v.p1,v.gameIndex,v.p1,v.p2,v.firstTurn)
                    e_sendStartMatchToClient:FireAllClients(v.p2,v.gameIndex,v.p1,v.p2,v.firstTurn)
                    return
                end
            end
            -- If no players are waiting then see if there is a free instance this player can be assigned to
            -- then send player to waiting area
            for k,v in pairs(self._table) do
                if (v.p1 == nil and v.p2 == nil ) then 
                    v.p1 = player
                    v.p1.character.transform.position = gamesInfo.waitingAreaPosition
                    e_sendMoveToWaitingAreaToClient:FireAllClients(v.p1)
                    return
                end
            end
            -- We are out of game instances
            -- add player to waiting queue and send player to waiting area
            player.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireAllClients(player)
            table.insert(self.playersInWaitingQueue,player)
        end
    }
end

function self:ServerAwake()
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
    playerHud = playerHudGameObject:GetComponent("PlayerHud")

    e_sendStartMatchToClient:Connect(function(player,gameIndex,p1,p2,firstTurn)
        if(client.localPlayer == player)then
            local raceGame = raceGames.transform:GetChild(gameIndex-1).gameObject:GetComponent("RaceGame")
            p1.character:Teleport(raceGame.transform.position,function() end)
            p2.character:Teleport(raceGame.transform.position,function() end)
            cameraRoot:GetComponent("RTSCamera").CenterOn(raceGame.transform.position)
            raceGame:GetComponent("RaceGame").StartMatch(p1,p2,firstTurn)
            playerHud.SetLocation( playerHud.Location().Game )
            playerHud.UpdateView()
        end
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function(player)
        if(client.localPlayer == player) then 
            playerHud.SetLocation( playerHud.Location().Lobby )
            playerHud.UpdateView()
            player.character:Teleport(gamesInfo.waitingAreaPosition,function() end)
            cameraRoot:GetComponent("RTSCamera").CenterOn(gamesInfo.waitingAreaPosition) 
        end
    end)
    e_sendMatchCancelledToClient:Connect(function(player)
        if(client.localPlayer == player) then 
            -- print("Other Player Left the match : Show message on HUD")
        end
    end)
end