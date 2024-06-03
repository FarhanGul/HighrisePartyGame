--Public Fields
--!SerializeField
local boardGameObject : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil
--!SerializeField
local audioManagerGameObject : GameObject = nil
--!SerializeField
local botGameObject : GameObject = nil

--Private Variables
local racers
local localRacer
local playerHud

--Classes
local function Racer(_id,_player,_isTurn)
    return {
        id = _id,
        player = _player,
        isTurn = _isTurn,
        lap = 1
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
        GetBotRacer = function(self)
            for k,v in pairs(self.list) do
                if(k.isBot ~= nil) then
                    return v
                end
            end
            return nil
        end,
        GetOpponentRacer = function(self,player)
            return self:GetFromId(self.GetOtherId(self:GetFromPlayer(player).id))
        end,
        GetOpponentPlayer = function(self,player)
            return self:GetFromId(self.GetOtherId(self:GetFromPlayer(player).id)).player
        end,
        GetOtherPlayer = function(self,id)
            return self:GetFromId(self.GetOtherId(id)).player
        end,
        GetOtherId = function(id)
            if id == 1 then return 2 else return 1 end
        end,
        IsLocalRacerTurn = function()
            return localRacer.isTurn
        end,
        GetRacerWhoseTurnItIs = function(self)
            for k,v in pairs(self.list) do
                if(v.isTurn) then
                    return v
                end
            end
            return nil
        end,
        GetPlayerWhoseTurnItIs = function(self)
            for k,v in pairs(self.list) do
                if(v.isTurn) then
                    return v.player
                end
            end
            return nil
        end,
        Print = function(self)
            for k,v in pairs(self.list) do
                print(client.localPlayer.name.."@ Player name : "..v.player.name)
                print(client.localPlayer.name.."@ Player id : "..v.id)
                print(client.localPlayer.name.."@ Is valid : ".. tostring(v.player.name == k.name))
            end
        end
    }
end

--Functions
function self:ClientAwake()
    playerHud = playerHudGameObject:GetComponent("RacerUIView")
end

function StartMatch(gameIndex, p1,p2,firstTurn,randomBoard)
    racers = Racers()
    racers:Add(Racer(1,p1,firstTurn == 1))
    racers:Add(Racer(2,p2,firstTurn == 2))
    playerHud.SetRacers( racers )
    playerHud.SetBoard( boardGameObject:GetComponent("Board") )
    localRacer = racers:GetFromPlayer(client.localPlayer)
    boardGameObject:GetComponent("Board").Initialize(gameIndex,racers,p1,p2,randomBoard)
    botGameObject:SetActive(gameIndex == -1)
end

function EndMatch()
    boardGameObject:GetComponent("Board").Uninitialize()
end

function GetRacers()
    return racers
end