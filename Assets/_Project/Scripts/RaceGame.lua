--!SerializeField
local diceTapHandler : TapHandler = nil
--!SerializeField
local boardGameObject : GameObject = nil
local board

-- Client
function self:ClientAwake()
    board = boardGameObject:GetComponent("Board")
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function() 
        
        board.Move(math.random(1,6))
    end)

    client.PlayerConnected:Connect(function(player)
        print(player.name .. " connected to the world on this client")
    end)

    client.PlayerDisconnected:Connect(function(player)
        print(player.name .. " disconnected from the world on this client")
    end)
end

-- Server
function self:ServerAwake()

    server.PlayerConnected:Connect(function(player)
        print(player.name .. " connected to the server")
    end)

    server.PlayerDisconnected:Connect(function(player)
        print(player.name .. " disconnected from the server")
    end)
end