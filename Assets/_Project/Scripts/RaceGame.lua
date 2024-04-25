
--!SerializeField
local myNumber : number = 0

--!SerializeField
local diceTapHandler : TapHandler = nil

-- Client
function self:ClientAwake()

    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function() 
        print("Object Tapped")
        print(math.random(1,6))
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