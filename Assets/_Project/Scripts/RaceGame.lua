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
local e_fetchGameStateFromServer = Event.new("fetchGameStateFromServer")
local e_sendGameStateToClient = Event.new("sendGameStateToClient")
local e_sendRollToClient = Event.new("sendRollToClient")
local e_sendRollToServer = Event.new("sendRollToServer")
--
local players = {}


function self:ClientAwake()
    board = boardGameObject:GetComponent("Board")
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        e_sendRollToServer:FireServer(math.random(1,6)) 
    end)
    e_sendGameStateToClient:Connect(function(newPlayers)
        players = newPlayers
        HandlePlayersUpdated()
    end)
    e_sendRollToClient:Connect(function(roll)
        board.Move(roll)
    end)
    e_fetchGameStateFromServer:FireServer()
end

function self:ServerAwake()
    server.PlayerConnected:Connect(function(player)
        print(player.name .. " connected to the world on this client")
        table.insert(players,player)
        e_sendGameStateToClient:FireAllClients(players)
    end)

    server.PlayerDisconnected:Connect(function(player)
        print(player.name .. " disconnected from the world on this client")
        table.remove(players,table.find(players, player))
        e_sendGameStateToClient:FireAllClients(players)
    end)

    e_fetchGameStateFromServer:Connect(function(player)
        e_sendGameStateToClient:FireAllClients(players)
    end)

    e_sendRollToServer:Connect(function(player, roll)
        e_sendRollToClient:FireAllClients(roll)
    end)
end

function HandlePlayersUpdated()
    waitingForPlayerUI.SetActive(waitingForPlayerUI,#players == 1)
end