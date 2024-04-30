--Enums
local State={Lobby = 0 , Game = 1}
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
--!SerializeField
local view : GameObject = nil
--

--Events
-- local e_fetchGameStateFromServer = Event.new("fetchGameStateFromServer")
-- local e_sendGameStateToClient = Event.new("sendGameStateToClient")
-- local e_propogateRollToClients = Event.new("propogateRollToClients")
local e_sendRollToServer = Event.new("sendRollToServer")
local e_sendRollToClients = Event.new("sendRollToClients")
--

--Private Variables
-- local players = {}
local racers
local localRacer
local state = State.Lobby
--

--Classes
local function Racer(_id,_player,_isTurn)
    return {
        id = _id,
        player = _player,
        isTurn = _isTurn
    }
end

local function Racers()
    return {
        list = {},
        Add = function(self,racer)
            self.list[racer.player] = racer
        end,
        GetFromPlayer = function(self,player)
            return self.list[player]
        end,
        GetFromId = function (self,id)
            for k,v in pairs(self.list) do
                if(v.id == id) then
                    return v
                end
            end
            return nil
        end,
        GetCount = function(self)
            local c = 0
            for k,v in pairs(self.list) do
                c+=1
            end
            return c
        end,
        GetOtherId = function(id)
            if id == 1 then return 2 else return 1 end
        end
    }
end


function self:ClientAwake()
    client.localPlayer.CharacterChanged:Connect(function(player, newCharacter, oldCharacter)
        if(oldCharacter == nil) then GoToLobby() end
    end)
end

function self:ServerAwake()
    e_sendRollToServer:Connect(function(player,id, roll)
        e_sendRollToClients:FireAllClients(id,roll)
    end)
end

function StartMatch(match)
    print("Start Match : "..match.p1.name.." vs "..match.p2.name)
    racers = Racers()
    racers:Add(Racer(1,match.p1,match.firstTurn == 1))
    racers:Add(Racer(2,match.p2,match.firstTurn == 2))
    localRacer = racers:GetFromPlayer(client.localPlayer)
    -- client.localPlayer.character:Teleport(Vector3.new(100,0,0),function() print("Teleported") end)
    -- client.localPlayer.character.transform.position = Vector3.new(100,0,0)
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        -- print("Dice tapped")
        if(localRacer.isTurn) then
            e_sendRollToServer:FireServer(localRacer.id ,math.random(1,6)) 
        end
    end)
    e_sendRollToClients:Connect(function(id, roll)
        boardGameObject:GetComponent("Board").Move(piecesGameObject.transform:GetChild(id-1).gameObject,roll)
        racers:GetFromId(id).isTurn = false
        racers:GetFromId(racers.GetOtherId(id)).isTurn = true
        print("Roll Recieved by client")
        UpdateHUD()
    end)
    state = State.Game
    UpdateHUD()
end

function GoToLobby()
    -- client.localPlayer.character:Teleport(Vector3.new(0,0,0),function() end)
    -- client.localPlayer.character.transform.position = Vector3.new(0,0,0)
    state = State.Lobby
    UpdateHUD()
end

function UpdateHUD()
    waitingForPlayerUI.SetActive(waitingForPlayerUI,state == State.Lobby)
    for i=1,2 do
        if(state == State.Lobby) then 
            view:GetComponent("RacerUIView").SetPlayer(i,nil)
        else
            view:GetComponent("RacerUIView").SetPlayer(i,racers:GetFromId(i))
        end
    end
end

-- function self:ClientAwake()
-- function ClientAwakeDisabled()
--     client.PlayerConnected:Connect(function(player)
--         -- print("Player Connected"..tostring(player.isLocal))
--         if (player.isLocal) then
--             diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
--                 if(players[player].isTurn) then
--                     e_sendRollToServer:FireServer(players[player].id ,math.random(1,6)) 
--                 end
--             end)
--             e_sendGameStateToClient:Connect(function(newPlayers)
--                 players = newPlayers
--                 HandlePlayersUpdated()
--             end)
--             e_propogateRollToClients:Connect(function(id, roll)
--                 boardGameObject:GetComponent("Board").Move(piecesGameObject.transform:GetChild(id-1).gameObject,roll)
--                 GetPlayerWithId(id).isTurn = false
--                 GetPlayerWithId(GetNextId((id))).isTurn = true
--                 UpdateHUD()
--             end)
--         end
--         e_fetchGameStateFromServer:FireServer()
--     end)
-- end

-- -- function self:ServerAwake()
-- function ServerAwakeDisabled()
--     server.PlayerConnected:Connect(function(player)
--         -- print(player.name .. " connected to the world on this client")
--         local nextAvailableId = GetNextAvailableId()
--         if(nextAvailableId ~= nil) -- Disable greater than two players for now, need to address this later with matchmaking
--         then
--             players[player] = {}
--             players[player].id = nextAvailableId
--             players[player].isTurn = false
--             players[player].player = player
--             if(GetPlayersCount()==2) then
--                 players[GetPlayerWithId(math.random(1,2)).player].isTurn = true
--             end
--             e_sendGameStateToClient:FireAllClients(players)
--         end
--     end)

--     server.PlayerDisconnected:Connect(function(player)
--         -- print(player.name .. " disconnected from the world on this client")
--         players[player] = nil
--         e_sendGameStateToClient:FireAllClients(players)
--     end)

--     e_fetchGameStateFromServer:Connect(function(player)
--         e_sendGameStateToClient:FireAllClients(players)
--     end)

--     e_sendRollToServer:Connect(function(player,id, roll)
--         e_propogateRollToClients:FireAllClients(id,roll)
--     end)
-- end

-- function HandlePlayersUpdated()
--     -- print("Handle Players Updated")
--     UpdateHUD()
--     waitingForPlayerUI.SetActive(waitingForPlayerUI,GetPlayersCount() == 1)
--     for i=0,piecesGameObject.transform.childCount-1,1 do
--         piecesGameObject.transform:GetChild(i).gameObject:SetActive(GetPlayerWithId(i+1) ~= nil )
--     end
--     if(GetPlayersCount() == 2) then
--         StartGame()
--     elseif(GetPlayersCount() == 1) then
--         ResetGame()
--     end
-- end

-- function ResetGame()
--     -- print("Reset Game")
-- end

-- function StartGame()
--     -- print("Start Game")
    
-- end

-- function GetNextAvailableId()
--     local availableIds = {1,2}
--     for k,v in pairs(players) do
--         table.remove(availableIds,v.id)
--     end
--     if (#availableIds == 0) then
--         return nil
--     else 
--         return availableIds[1]
--     end
-- end

-- function GetPlayerWithId(id)
--     for k,v in pairs(players) do
--         if(v.id == id) then
--             return v
--         end
--     end
--     return nil
-- end

-- function GetPlayersCount()
--     local c = 0
--     for k,v in pairs(players) do
--             c+=1
--     end
--     return c
-- end