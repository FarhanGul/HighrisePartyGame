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
    cardManagerRelativePosition = Vector3.new(0.4,5,1.16),
    player1SpawnRelativePosition = Vector3.new(5.5,0.5,0),
    player2SpawnRelativePosition = Vector3.new(-5.5,0.5,0)
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
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local cameraWaitingAreaRotation : Vector3 = nil
--!SerializeField
local cameraGameRotation : Vector3 = nil

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
                    v.p1.character.transform.position = ServerVectorAdd(gamesInfo.playerGamePositions[v.gameIndex] , gamesInfo.player1SpawnRelativePosition )
                    v.p2.character.transform.position = ServerVectorAdd(gamesInfo.playerGamePositions[v.gameIndex] , gamesInfo.player2SpawnRelativePosition )
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
    -- for i = 1 , 10 do
    --     print("--------")
    --     local randBoard = GenerateRandomBoard()
    --     for i = 1 , #randBoard do
    --         print(randBoard[i])
    --     end
    -- end
    playerHud = playerHudGameObject:GetComponent("RacerUIView")
    cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraWaitingAreaRotation)
    -- playerHudGameObject.transform.parent.position = gamesInfo.worldSpaceUiWaitingAreaPosition

    playerHud.ShowWelcomeScreen(function()
        e_sendReadyForMatchmakingToServer:FireServer()
    end)
    e_sendStartMatchToClient:Connect(function(gameIndex,p1,p2,firstTurn,randomBoard)
        local raceGame = raceGames.transform:GetChild(gameIndex-1).gameObject:GetComponent("RaceGame")
        p1.character:Teleport(raceGame.transform.position + gamesInfo.player1SpawnRelativePosition,function() end)
        p2.character:Teleport(raceGame.transform.position + gamesInfo.player2SpawnRelativePosition,function() end)
        if(p1 == client.localPlayer or p2 == client.localPlayer) then    
            -- playerHudGameObject.transform.parent:SetParent(raceGame.transform)
            -- playerHudGameObject.transform.parent.localPosition = gamesInfo.worldSpaceUiRelativeGamePosition
            cardManagerGameObject.transform:SetParent(raceGame.transform)
            cardManagerGameObject.transform.localPosition = gamesInfo.cardManagerRelativePosition
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraGameRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(raceGame.transform.position)
            raceGame:GetComponent("RaceGame").StartMatch(gameIndex,p1,p2,firstTurn,randomBoard)
            playerHud.SetLocation( playerHud.Location().Game )
            playerHud.ShowGameView()
        end
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function(player)
        player.character:Teleport(gamesInfo.waitingAreaPosition,function() end)
        if(player == client.localPlayer) then
            playerHud.SetLocation( playerHud.Location().Lobby )
            -- playerHudGameObject.transform.parent.position = gamesInfo.worldSpaceUiWaitingAreaPosition
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
    local raceGame = raceGames.transform:GetChild(_gameIndex-1).gameObject:GetComponent("RaceGame")
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

function GenerateRandomBoard()
    -- Total tiles = 32
    local _deckWeights = {
        Default = 17,
        Draw = 8,
        Mine = 2,
        Draw3 = 1,
    }
    local _deck = {}
    for k , v in pairs(_deckWeights) do
        for i = 1, v do 
            table.insert(_deck,k)
        end
    end
    ShuffleArray(_deck)
    local teleportIndex1 = math.random(1,31)
    local teleportIndex2 = GetRandomExcluding(1, 31, {teleportIndex1})
    local anomalyIndex = GetRandomExcluding(16, 31, {teleportIndex1,teleportIndex2})
    local _tiles = {}
    for i = 1 , 31 do
        if ( i == teleportIndex1 or i == teleportIndex2) then
            _tiles[i] = "Teleport"
        elseif ( i == anomalyIndex) then
            _tiles[i] = "Anomaly"
        else
            _tiles[i] = _deck[1]
            table.remove(_deck,1)
        end
    end
    return _tiles
end

function ShuffleArray(arr)
    local n = #arr
    for i = n, 2, -1 do
        local j = math.random(i) -- Generate a random index
        arr[i], arr[j] = arr[j], arr[i] -- Swap elements
    end
end

function GetRandomExcluding(from, to, exclude)
    local rand = math.random(from , to)
    while( exclude[rand] ~= nil) do
        rand = math.random(from , to)
    end
    return rand
end