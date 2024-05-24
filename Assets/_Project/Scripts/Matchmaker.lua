local gamesInfo = {
    totalGameInstances = 256,
    waitingAreaPosition = Vector3.new(0,0,0),
    player1SpawnRelativePosition = Vector3.new(5.3,0.96,0),
    player2SpawnRelativePosition = Vector3.new(-5.3,0.96,0)
}

-- Total Tiles 31
local tileConfigurations = {
    {
        -- 1 - A bit of everything
        Default = 10,
        Draw = 4,
        Mine = 2,
        Draw3 = 1,
        Burn = 2,
        Snare = 1,
        Recharge = 2,
        Draw2 = 2,
        Dome = 4,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 2 - Lots of cards and lot of burns
        Default = 8,
        Draw = 8,
        Mine = 2,
        Draw3 = 1,
        Burn = 4,
        Snare = 1,
        Recharge = 1,
        Draw2 = 2,
        Dome = 1,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 3 - Lots of mines and recharges
        Default = 8,
        Draw = 4,
        Mine = 5,
        Draw3 = 1,
        Snare = 2,
        Recharge = 4,
        Draw2 = 2,
        Dome = 2,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 4 - Safe
        Default = 10,
        Draw = 8,
        Recharge = 2,
        Mine = 2,
        Draw2 = 2,
        Dome = 4,
        Teleport = 2,
        Anomaly = 1
    }
}

--Public Variables
--!SerializeField
local raceGame : GameObject = nil
--!SerializeField
local cameraRoot : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local cameraWaitingAreaRotation : Vector3 = nil
--!SerializeField
local cameraGameRotation : Vector3 = nil

--Private Variables
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
            for i=1, gamesInfo.totalGameInstances do
                table.insert(self._table,GameInstance(i,nil,nil,nil))
            end
        end,
        HandleGameFinished = function(self,gameIndex)
            if(self._table[gameIndex].p1 == nil or self._table[gameIndex].p2 == nil) then return end
            self._table[gameIndex].p1.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireAllClients(self._table[gameIndex].p1)
            self._table[gameIndex].p2.character.transform.position = gamesInfo.waitingAreaPosition
            e_sendMoveToWaitingAreaToClient:FireAllClients(self._table[gameIndex].p2)
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
                        e_sendMoveToWaitingAreaToClient:FireAllClients(otherPlayer)
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
                    v.p1.character.transform.position = ServerVectorAdd(GetGameInstancePosition(v.gameIndex) , gamesInfo.player1SpawnRelativePosition )
                    v.p2.character.transform.position = ServerVectorAdd(GetGameInstancePosition(v.gameIndex) , gamesInfo.player2SpawnRelativePosition )
                    e_sendStartMatchToClient:FireAllClients(v.gameIndex,v.p1,v.p2,v.firstTurn,GenerateRandomBoard())
                    return
                end
            end
            -- If no players are waiting then see if there is a free instance this player can be assigned to
            -- then send player to waiting area
            for k,v in pairs(self._table) do
                if (v.p1 == nil and v.p2 == nil ) then 
                    v.p1 = player
                    if(not IsPlayerInWaitingArea(v.p1)) then
                        v.p1.character.transform.position = gamesInfo.waitingAreaPosition
                        e_sendMoveToWaitingAreaToClient:FireAllClients(v.p1)
                    end
                    return
                end
            end
            -- We are out of game instances
            -- add player to waiting queue and send player to waiting area
            if(not IsPlayerInWaitingArea(player)) then
                player.character.transform.position = gamesInfo.waitingAreaPosition
                e_sendMoveToWaitingAreaToClient:FireAllClients(player)
            end
            table.insert(self.playersInWaitingQueue,player)
        end
    }
end

function self:ServerAwake()
    ValidateTileConfigurations()
    gameInstances = GameInstances()
    gameInstances:Initialize()
    server.PlayerConnected:Connect(function(player)
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
    cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraWaitingAreaRotation)
    playerHud.ShowWelcomeScreen(function()
        e_sendReadyForMatchmakingToServer:FireServer()
    end)
    e_sendStartMatchToClient:Connect(function(gameIndex,p1,p2,firstTurn,randomBoard)
        local raceGame = raceGame:GetComponent("RaceGame")
        local instancePosition = GetGameInstancePosition(gameIndex) 
        p1.character:Teleport(instancePosition + gamesInfo.player1SpawnRelativePosition,function() end)
        p2.character:Teleport(instancePosition + gamesInfo.player2SpawnRelativePosition,function() end)
        if(p1 == client.localPlayer or p2 == client.localPlayer) then    
            raceGame.transform.position = instancePosition
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraGameRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(instancePosition)
            raceGame:GetComponent("RaceGame").StartMatch(gameIndex,p1,p2,firstTurn,randomBoard)
            playerHud.SetLocation( playerHud.Location().Game )
            playerHud.ShowGameView()
        end
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function(player)
        player.character:Teleport(gamesInfo.waitingAreaPosition,function() end)
        if(player == client.localPlayer) then
            playerHud.SetLocation( playerHud.Location().Lobby )
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraWaitingAreaRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(gamesInfo.waitingAreaPosition) 
        end
    end)
    e_sendMatchCancelledToClient:Connect(function()
        playerHud.ShowOpponentLeft(function()
            e_sendReadyForMatchmakingToServer:FireServer()
        end)
    end)
end

function GameFinished(_gameIndex,playerWhoWon)
    audioManagerGameObject:GetComponent("AudioManager"):PlayResultNotify()
    local raceGame = raceGame:GetComponent("RaceGame")
    playerHud.ShowResult(client.localPlayer == playerWhoWon,function()
        e_sendReadyForMatchmakingToServer:FireServer()
    end)
    if(client.localPlayer ~= playerWhoWon) then 
        e_sendMatchFinishedToServer:FireServer(_gameIndex)
    end
end

function IsPlayerInWaitingArea(player)
    return ServerVectorDistance(player.character.transform.position, gamesInfo.waitingAreaPosition) < 50
end

function ServerVectorDistance(a,b)
    return math.sqrt( ( (b.x - a.x) *  (b.x - a.x) ) + ( (b.y - a.y) *  (b.y - a.y) ) + ( (b.z - a.z) *  (b.z - a.z) ) )
end

function ServerVectorAdd(a,b)
    return Vector3.new(a.x+b.x, a.y+b.y, a.z+b.z)
end

function ValidateTileConfigurations()
    for i =1 , #tileConfigurations do 
        local _count = 0
        for k , v in pairs(tileConfigurations[i]) do
            _count += v
        end
        if(_count ~= 31) then
            print("Tile Validation for "..i.." Failed with count ".._count)
        end
    end
end

function GenerateRandomBoard()
    local printOutput = false
    local randomConfigIndex = math.random(1,#tileConfigurations)
    -- randomConfigIndex = 2
    local randomConfig = tileConfigurations[randomConfigIndex]
    if(printOutput) then
        print("<Config Start>")
        print("ConfigIndex : "..randomConfigIndex)
        -- for k,v in pairs(randomConfig) do
        --     print(k.." : "..v)
        -- end
        print("<Config End>")
    end
    local teleportIndex1,teleportIndex2,anomalyIndex
    local usedIndices = {}
    if(randomConfig["Anomaly"] ~= nil) then
        anomalyIndex = GetRandomExcluding(16, 31, usedIndices)
        table.insert(usedIndices,anomalyIndex)
    end
    if(randomConfig["Teleport"] ~= nil) then
        teleportIndex1 = GetRandomExcluding(1, 16,usedIndices)
        table.insert(usedIndices,teleportIndex1)
        teleportIndex2 = GetRandomExcluding(1, 16,usedIndices)
        table.insert(usedIndices,teleportIndex2)
    end
    local remaingTiles = {}
    for k , v in pairs(randomConfig) do
        for i = 1, v do 
            if ( k ~= "Anomaly" and k ~= "Teleport") then
                table.insert(remaingTiles,k)
            end
        end
    end
    for i = 1 , 5 do ShuffleArray(remaingTiles) end

    local finalBoard = {}
    for i = 1 , 31 do
        if ( i == teleportIndex1 or i == teleportIndex2) then
            finalBoard[i] = "Teleport"
        elseif ( i == anomalyIndex) then
            finalBoard[i] = "Anomaly"
        else
            finalBoard[i] = remaingTiles[1]
            table.remove(remaingTiles,1)
        end
    end
    if(printOutput) then
        print("<Board Start>")
        print("Is Valid : "..tostring(#finalBoard == 31))
        -- for i = 1 , #finalBoard do
        --     print(i..finalBoard[i])
        -- end
        print("<Board End>")
    end
    return finalBoard
end

function ShuffleArray(arr)
    local n = #arr
    for i = n, 2, -1 do
        local j = math.random(i) -- Generate a random index
        arr[i], arr[j] = arr[j], arr[i] -- Swap elements
    end
end

function GetGameInstancePosition(_gameIndex)
    return Vector3.new(_gameIndex * 500, 0, 0)
end

function GetRandomExcluding(from, to, exclude)
    local rand = math.random(from , to)
    while( exclude[rand] ~= nil) do
        rand = math.random(from , to)
    end
    return rand
end