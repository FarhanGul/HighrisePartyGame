--Enums
local GameState = {
    waitingForPlayers = 1,
    playing = 2,
}
--

--Public Fields
--!SerializeField
local waitingForPlayerUI : GameObject = nil
--!SerializeField
local diceTapHandler : TapHandler = nil
--!SerializeField
local boardGameObject : GameObject = nil
--!SerializeField
local piecesGameObject : GameObject = nil
--

--Events
local e_fetchGameStateFromServer = Event.new("fetchGameStateFromServer")
local e_sendGameStateToClient = Event.new("sendGameStateToClient")
local e_sendRollToClient = Event.new("sendRollToClient")
local e_sendRollToServer = Event.new("sendRollToServer")
--

--Private Variables
local players = {}
local playerWhoseTurnItIs
local board
local gameState = GameState.waitingForPlayers
--

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
        local nextAvailableId = GetNextAvailableId()
        if(nextAvailableId ~= nil) -- Disable greater than two players for now, need to address this later with matchmaking
        then
            players[player] = nextAvailableId
            for k,v in pairs(players) do
            end
            e_sendGameStateToClient:FireAllClients(players)
        end
    end)

    server.PlayerDisconnected:Connect(function(player)
        print(player.name .. " disconnected from the world on this client")
        players[player] = nil
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
    print(GetPlayersCount())
    waitingForPlayerUI.SetActive(waitingForPlayerUI,GetPlayersCount() == 1)
    for i=0,piecesGameObject.transform.childCount-1,1 do
        piecesGameObject.transform:GetChild(i).gameObject:SetActive(PlayersHasId(i+1))
    end
    if(GetPlayersCount() == 2)
    then
        StartGame()
    elseif(#players == 1)
    then
        ResetGame()
    end
end

function ResetGame()
    -- Reset board pieces
end

function StartGame()
    
end


function GetNextAvailableId()
    local availableIds = {1,2}
    for k,v in pairs(players) do
        table.remove(availableIds,v)
    end
    if (#availableIds == 0) then
        return nil
    else 
        return availableIds[1]
    end
end

function PlayersHasId(id)
    for k,v in pairs(players) do
        if(v == id) then
            return true
        end
    end
    return false
end

function GetPlayersCount()
    local c = 0
    for k,v in pairs(players) do
            c+=1
    end
    return c
end