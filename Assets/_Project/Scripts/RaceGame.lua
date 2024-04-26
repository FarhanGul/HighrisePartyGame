--!SerializeField
local waitingForPlayerUI : GameObject = nil
--!SerializeField
local diceTapHandler : TapHandler = nil
--!SerializeField
local boardGameObject : GameObject = nil
local board
--Game States
local waitingForPlayers = 0
local playing = 1
--
local gameState = waitingForPlayers
--Events
local fetchGameStateFromServer = Event.new("fetchGameStateFromServer")
local sendGameStateToClient = Event.new("sendGameStateToClient")
--
local players = {}


function self:ClientAwake()
    board = boardGameObject:GetComponent("Board")
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function() 
        board.Move(math.random(1,6))
    end)
    sendGameStateToClient:Connect(function(newPlayers)
        players = newPlayers
        HandlePlayersUpdated()
    end)
    fetchGameStateFromServer:FireServer()
end

function self:ServerAwake()
    server.PlayerConnected:Connect(function(player)
        print(player.name .. " connected to the world on this client")
        table.insert(players,player)
        sendGameStateToClient:FireAllClients(players)
    end)

    server.PlayerDisconnected:Connect(function(player)
        print(player.name .. " disconnected from the world on this client")
        table.remove(players,table.find(players, player))
        sendGameStateToClient:FireAllClients(players)
    end)

    fetchGameStateFromServer:Connect(function(player)
        sendGameStateToClient:FireAllClients(players)
    end)
end

function HandlePlayersUpdated()
    waitingForPlayerUI.SetActive(waitingForPlayerUI,#players == 1)
end