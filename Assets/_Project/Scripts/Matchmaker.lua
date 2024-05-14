local gamesInfo = {
    count = 2,
    playerGamePositions = {
        Vector3.new(500,0,0),
        Vector3.new(-500,0,0),
        Vector3.new(1000,0,0),
        Vector3.new(-1000,0,0),
        Vector3.new(1500,0,0),
        Vector3.new(-1500,0,0),
    },
    waitingAreaPosition = Vector3.new(0,0,0),
    worldSpaceUiWaitingAreaPosition = Vector3.new(0,3.61,-8.06),
    worldSpaceUiRelativeGamePosition = Vector3.new(0,3.61,-8.06),
    cardManagerRelativePosition = Vector3.new(0.4,5,-1.28)
}

--Public Variables
--!SerializeField
local raceGames : GameObject = nil
--!SerializeField
local cameraRoot : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil

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
local e_sendReadyForMatchmakingToServer= Event.new("sendReadyForMatchmakingToServer")
local e_sendMatchFinishedToServer= Event.new("sendMatchFinishedToServer")
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
        HandleGameFinished = function(self,gameIndex)
            if(self._table[gameIndex].p1 == nil or self._table[gameIndex].p2 == nil) then return end
            self._table[gameIndex].p1.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireClient(self._table[gameIndex].p1)
            self._table[gameIndex].p2.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireClient(self._table[gameIndex].p2)
            self._table[gameIndex].p1 = nil
            self._table[gameIndex].p2 = nil
            self:HandlePlayerSlotsFreed(2)
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
            -- if player was inside game when they left, notify other player
            for k,v in pairs(self._table) do
                if(v.p1 ~= nil and v.p2 ~= nil) then
                    if ( v.p1 == player or v.p2 == player ) then
                        local otherPlayer
                        if (v.p1 == player) then otherPlayer = v.p2 else otherPlayer = v.p1 end
                        v.p1 = nil
                        v.p2 = nil
                        otherPlayer.character.transform.position = gamesInfo.waitingAreaPosition
                        e_sendMoveToWaitingAreaToClient:FireClient(otherPlayer)
                        e_sendMatchCancelledToClient:FireClient(otherPlayer)
                        self:HandlePlayerSlotsFreed(2)
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
                    v.p1.character.transform.position = gamesInfo.playerGamePositions[v.gameIndex]
                    v.p2.character.transform.position = gamesInfo.playerGamePositions[v.gameIndex]
                    e_sendStartMatchToClient:FireClient(v.p1,v.gameIndex,v.p1,v.p2,v.firstTurn)
                    e_sendStartMatchToClient:FireClient(v.p2,v.gameIndex,v.p1,v.p2,v.firstTurn)
                    return
                end
            end
            -- If no players are waiting then see if there is a free instance this player can be assigned to
            -- then send player to waiting area
            for k,v in pairs(self._table) do
                if (v.p1 == nil and v.p2 == nil ) then 
                    v.p1 = player
                    v.p1.character.transform.position = gamesInfo.waitingAreaPosition
                    e_sendMoveToWaitingAreaToClient:FireClient(v.p1)
                    return
                end
            end
            -- We are out of game instances
            -- add player to waiting queue and send player to waiting area
            player.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireClient(player)
            table.insert(self.playersInWaitingQueue,player)
        end
    }
end

function self:ServerAwake()
    gameInstances = GameInstances()
    gameInstances:Initialize()
    server.PlayerConnected:Connect(function(player)
        -- print(player.name.." connected with id "..player.id)
    end)
    server.PlayerDisconnected:Connect(function(player)
        gameInstances:HandlePlayerLeft(player)
    end)
    e_sendReadyForMatchmakingToServer:Connect(function(player)
        gameInstances:HandleNewPlayer(player)
    end)
    e_sendMatchFinishedToServer:Connect(function(player,_gameIndex)
        gameInstances:HandleGameFinished(_gameIndex)
    end)
end

function self:ClientAwake()
    playerHud = playerHudGameObject:GetComponent("RacerUIView")
    playerHudGameObject.transform.parent.position = gamesInfo.worldSpaceUiWaitingAreaPosition

    playerHud.ShowWelcomeScreen(function()
        e_sendReadyForMatchmakingToServer:FireServer()
    end)
    e_sendStartMatchToClient:Connect(function(gameIndex,p1,p2,firstTurn)
        local raceGame = raceGames.transform:GetChild(gameIndex-1).gameObject:GetComponent("RaceGame")
        p1.character:Teleport(raceGame.transform.position,function() end)
        p2.character:Teleport(raceGame.transform.position,function() end)
        playerHudGameObject.transform.parent:SetParent(raceGame.transform)
        playerHudGameObject.transform.parent.localPosition = gamesInfo.worldSpaceUiRelativeGamePosition
        cardManagerGameObject.transform:SetParent(raceGame.transform)
        cardManagerGameObject.transform.localPosition = gamesInfo.cardManagerRelativePosition
        -- print(client.localPlayer.name.." set card manager")
        cameraRoot:GetComponent("RTSCamera").CenterOn(raceGame.transform.position)
        raceGame:GetComponent("RaceGame").StartMatch(gameIndex,p1,p2,firstTurn)
        playerHud.SetLocation( playerHud.Location().Game )
        playerHud.UpdateView()
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function()
        playerHud.SetLocation( playerHud.Location().Lobby )
        playerHud.UpdateView()
        client.localPlayer.character:Teleport(gamesInfo.waitingAreaPosition,function() end)
        playerHudGameObject.transform.parent.position = gamesInfo.worldSpaceUiWaitingAreaPosition
        cameraRoot:GetComponent("RTSCamera").CenterOn(gamesInfo.waitingAreaPosition) 
    end)
    e_sendMatchCancelledToClient:Connect(function()
        playerHud.ShowOpponentLeft(function()
            e_sendReadyForMatchmakingToServer:FireServer()
        end)
    end)
end

function GameFinished(_gameIndex)
    local raceGame = raceGames.transform:GetChild(_gameIndex-1).gameObject:GetComponent("RaceGame")
    local playerWhoWon = raceGame.GetRacers():GetPlayerWhoseTurnItIs()
    playerHud.ShowResult(client.localPlayer == playerWhoWon,function()
        e_sendReadyForMatchmakingToServer:FireServer()
    end)
    if(client.localPlayer ~= playerWhoWon) then 
        e_sendMatchFinishedToServer:FireServer(_gameIndex)
    end
end