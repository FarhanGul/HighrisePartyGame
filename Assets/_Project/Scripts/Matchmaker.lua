local boardGenerator = require("BoardGenerator")

local gamesInfo = {
    totalGameInstances = 256,
    waitingAreaPosition = Vector3.new(0,0,0),
    player1SpawnRelativePosition = Vector3.new(5.3,0.96,0),
    player2SpawnRelativePosition = Vector3.new(-5.3,0.96,0)
}

--Public Variables
--!SerializeField
local raceGame : GameObject = nil
--!SerializeField
local cameraRoot : GameObject = nil
--!SerializeField
local playGameHandlerGameObject : GameObject = nil
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
local onSlotStatusUpdatedEvent = {}
-- InProgress, OpponentLeft , Finished
local matchStatus
--

-- Events
local e_sendStartMatchToClient = Event.new("sendStartMatchToClient")
local e_sendMatchCancelledToClient = Event.new("sendMatchCancelledToClient")
local e_sendMoveToWaitingAreaToClient = Event.new("sendMoveToWaitingAreaToClient")
local e_sendReadyForMatchmakingToServer = Event.new("sendReadyForMatchmakingToServer")
local e_sendCancelMatchmakingToServer = Event.new("sendCancelMatchmakingToServer")
local e_sendLeaveMatchToServer = Event.new("sendLeaveMatchToServer")
local e_sendMatchFinishedToServer = Event.new("sendMatchFinishedToServer")
local e_sendMoveRequestToServer = Event.new("sendMoveRequestToServer")
local e_sendMoveCommandToClient = Event.new("sendMoveCommandToClient")
local e_sendSlotStatusToClient = Event.new("sendSlotStatusToClient")
local e_requestSlotStatusFromServer = Event.new("requestSlotStatusFromServer")
--

--Classes
function GameInstance(_gameIndex,_p1,_p2,_firstTurn)
    return{
        gameIndex = _gameIndex,
        firstTurn = _firstTurn,
        p1 = _p1,
        p2 = _p2,
        isGameFinished = false
    }
end

function GameInstances()
    return{
        _table = {},
        _slots = {},
        Initialize = function(self)
            for i=1, gamesInfo.totalGameInstances do
                table.insert(self._table,GameInstance(i,nil,nil,nil))
            end
        end,
        SendSlotStatusToClient = function(self,player)
            e_sendSlotStatusToClient:FireClient(player,1,self._slots[1])
            e_sendSlotStatusToClient:FireClient(player,2,self._slots[2])
        end,
        HandleGameFinished = function(self,gameIndex)
            self._table[gameIndex].isGameFinished = true
        end,
        HandlePlayerLeftGame = function(self,player)
            -- if player was inside game when they left and match has not finished, notify other player that opponent left match
            for k,v in pairs(self._table) do
                if(v.p1 ~= nil and v.p2 ~= nil and not v.isGameFinished) then
                    if ( v.p1 == player or v.p2 == player ) then
                        local otherPlayer
                        if (v.p1 == player) then otherPlayer = v.p2 else otherPlayer = v.p1 end
                        e_sendMatchCancelledToClient:FireClient(otherPlayer)
                    end
                end
            end

            -- Remove player form game instance table
            for k,v in pairs(self._table) do
                if (v.p1 == player) then v.p1 = nil end
                if (v.p2 == player) then v.p2 = nil end
            end
        end,
        HandlePlayerLeavesMatchmaking = function(self,player)
            if(player == self._slots[1]) then
                self._slots[1] = nil 
                e_sendSlotStatusToClient:FireAllClients(1,nil)
            end
            if(player == self._slots[2]) then
                self._slots[2] = nil
                e_sendSlotStatusToClient:FireAllClients(2,nil)
            end
        end,
        HandlePlayerEntersMatchmaking = function(self,player,slot)
            if(self._slots[slot] ~= nil) then
                -- print("Slot already occupied")
                return
            else
                -- notify all clients that a slot was just occupied provided match is not about to start
                -- print("notify all clients that a slot was just occupied and match is not about to start")
                if (self._slots[1] == nil or self._slots[2] == nil ) then
                    e_sendSlotStatusToClient:FireAllClients(slot,player)
                end
            end

            self._slots[slot] = player
            -- if both slots are full create match
            -- then send both players to game area
            -- print("1 : "..tostring(self._slots[1] == nil))
            -- print("2 : "..tostring(self._slots[2] == nil))
            if (self._slots[1] ~= nil and self._slots[2] ~= nil ) then
                -- Find free instance
                for k,v in pairs(self._table) do
                    if (v.p1 == nil and v.p2 == nil ) then
                        v.p1 = self._slots[1]
                        v.p2 = self._slots[2]
                        v.firstTurn = math.random(1,2)
                        v.p1.character.transform.position = ServerVectorAdd(GetGameInstancePosition(v.gameIndex) , gamesInfo.player1SpawnRelativePosition )
                        v.p2.character.transform.position = ServerVectorAdd(GetGameInstancePosition(v.gameIndex) , gamesInfo.player2SpawnRelativePosition )
                        v.isGameFinished = false
                        e_sendStartMatchToClient:FireAllClients(v.gameIndex,v.p1,v.p2,v.firstTurn,boardGenerator.GenerateRandomBoard())
                        self._slots[1] = nil
                        self._slots[2] = nil
                        e_sendSlotStatusToClient:FireAllClients(1,nil)
                        e_sendSlotStatusToClient:FireAllClients(2,nil)
                        return
                    end
                end
            end
        end
    }
end

function self:ServerAwake()
    boardGenerator.ValidateTileConfigurations()
    gameInstances = GameInstances()
    gameInstances:Initialize()
    server.PlayerConnected:Connect(function(player)
    end)
    server.PlayerDisconnected:Connect(function(player)
        gameInstances:HandlePlayerLeavesMatchmaking(player)
        gameInstances:HandlePlayerLeftGame(player)
    end)
    e_sendLeaveMatchToServer:Connect(function(player)
        gameInstances:HandlePlayerLeftGame(player)
    end)
    e_sendCancelMatchmakingToServer:Connect(function(player)
        gameInstances:HandlePlayerLeavesMatchmaking(player)
    end)
    e_sendReadyForMatchmakingToServer:Connect(function(player,slot)
        gameInstances:HandlePlayerEntersMatchmaking(player,slot)
    end)
    e_sendMatchFinishedToServer:Connect(function(player,_gameIndex)
        gameInstances:HandleGameFinished(_gameIndex)
    end)
    e_sendMoveRequestToServer:Connect(function(player,newPlayerPosition,newCameraRotation)
        player.character.transform.position = newPlayerPosition
        e_sendMoveCommandToClient:FireAllClients(player,newPlayerPosition,newCameraRotation)
    end)
    e_requestSlotStatusFromServer:Connect(function(player)
        gameInstances:SendSlotStatusToClient(player)
    end)
end

function self:ClientAwake()
    playerHud = playerHudGameObject:GetComponent("RacerUIView")
    cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraWaitingAreaRotation)
    e_sendStartMatchToClient:Connect(function(gameIndex,p1,p2,firstTurn,randomBoard)
        local instancePosition = GetGameInstancePosition(gameIndex)
        SetPlayerPositionOnClient(p1,instancePosition + gamesInfo.player1SpawnRelativePosition)
        SetPlayerPositionOnClient(p2,instancePosition + gamesInfo.player2SpawnRelativePosition)
        if(p1 == client.localPlayer or p2 == client.localPlayer) then
            matchStatus = "InProgress"
            raceGame.transform.position = instancePosition
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraGameRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(instancePosition)
            raceGame:GetComponent("RaceGame").StartMatch(gameIndex,p1,p2,firstTurn,randomBoard)
            playerHud.SetLocation( playerHud.Location().Game )
            playerHud.ShowGameView()
        end
    end)
    e_sendMoveToWaitingAreaToClient:Connect(function(player)
        SetPlayerPositionOnClient(player,gamesInfo.waitingAreaPosition)
        if(player == client.localPlayer) then
            playerHud.SetLocation( playerHud.Location().Lobby )
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(cameraWaitingAreaRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(gamesInfo.waitingAreaPosition)
        end
    end)
    e_sendMoveCommandToClient:Connect(function(player,newPlayerPosition,newCameraRotation)
        SetPlayerPositionOnClient(player,newPlayerPosition)
        if(player == client.localPlayer) then
            cameraRoot:GetComponent("CustomRTSCamera").SetRotation(newCameraRotation)
            cameraRoot:GetComponent("CustomRTSCamera").CenterOn(newPlayerPosition)
        end
    end)
    e_sendMatchCancelledToClient:Connect(function()
        matchStatus = "OpponentLeft"
        playerHud.ShowOpponentLeft(function() end)
    end)
    e_sendSlotStatusToClient:Connect(function(slot,player)
        for i = 1 , #onSlotStatusUpdatedEvent do
            onSlotStatusUpdatedEvent[i](slot,player)
        end
    end)
end

function SetPlayerPositionOnClient(player,newPosition)
    player.character.usePathfinding = false
    player.character:Teleport(newPosition,function() end)
    player.character.usePathfinding = true
end

function StartBotMatch()
    local bot = {
        isBot = true,
        name = "Bot"
    }
    matchStatus = "InProgress"
    raceGame:GetComponent("RaceGame").StartMatch(-1,client.localPlayer,bot,math.random(1,2),boardGenerator.GenerateRandomBoard())
    local instancePosition = GetGameInstancePosition(-1)
    e_sendMoveRequestToServer:FireServer(instancePosition + gamesInfo.player1SpawnRelativePosition,cameraGameRotation)
    raceGame.transform.position = instancePosition
    playerHud.SetLocation( playerHud.Location().Game )
    playerHud.ShowGameView()
end

function RequestSlotStatus()
    e_requestSlotStatusFromServer:FireServer()
end

function SubscribeOnSlotStatusUpdated(event)
    table.insert(onSlotStatusUpdatedEvent,event)
end

function EnterMatchmaking(slot)
    e_sendReadyForMatchmakingToServer:FireServer(slot)
end

function ExitMatchmaking()
    e_sendCancelMatchmakingToServer:FireServer()
end

function EndMatch()
    e_sendLeaveMatchToServer:FireServer()
    e_sendMoveRequestToServer:FireServer(gamesInfo.waitingAreaPosition,cameraWaitingAreaRotation)
    raceGame:GetComponent("RaceGame").EndMatch()
end

function GameFinished(_gameIndex,playerWhoWon)
    matchStatus = "Finished"
    audioManagerGameObject:GetComponent("AudioManager"):PlayResultNotify()
    playerHud.ShowResult(client.localPlayer == playerWhoWon,function()end)
    if( _gameIndex ~= -1 and client.localPlayer ~= playerWhoWon) then
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

function GetGameInstancePosition(_gameIndex)
    return Vector3.new(_gameIndex * 500, 0, 0)
end

function GetMatchStatus()
    return matchStatus
end