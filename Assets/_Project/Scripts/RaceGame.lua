--Public Fields
--!SerializeField
local diceTapHandler : TapHandler = nil
--!SerializeField
local boardGameObject : GameObject = nil
--!SerializeField
local playerHudGameObject : GameObject = nil
--!SerializeField
local cardManagerGameObject : GameObject = nil

--Events
local e_sendRollToServer = Event.new("sendRollToServer")
local e_sendRollToClients = Event.new("sendRollToClients")

--Private Variables
local racers
local localRacer
local playerHud
local isRollSentToServer

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
        GetOpponentPlayer = function(self,player)
            return self:GetFromId(self.GetOtherId(self:GetFromPlayer(player).id)).player
        end,
        GetOtherId = function(id)
            if id == 1 then return 2 else return 1 end
        end,
        IsLocalRacerTurn = function()
            return localRacer.isTurn
        end,
        GetPlayerWhoseTurnItIs = function(self)
            for k,v in pairs(self.list) do
                if(v.isTurn) then
                    return v.player
                end
            end
            return nil
        end
    }
end

--Functions
function self:ClientAwake()
    playerHud = playerHudGameObject:GetComponent("RacerUIView")
    e_sendRollToClients:Connect(function(id, roll)
        boardGameObject:GetComponent("Board").Move(id,roll,function() 
            local skipOpponentTurn = false
            if(cardManagerGameObject:GetComponent("CardManager").GetPlayedCard() == "Zap") then skipOpponentTurn = true end
            if(not skipOpponentTurn) then
                racers:GetFromId(id).isTurn = false
                racers:GetFromId(racers.GetOtherId(id)).isTurn = true
                diceTapHandler.gameObject:SetActive(racers.IsLocalRacerTurn())
                playerHud.UpdateView()
            end
            isRollSentToServer = false
            boardGameObject:GetComponent("Board").TurnChanged()
        end)
    end)
    diceTapHandler.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(localRacer.isTurn and not isRollSentToServer) then
            isRollSentToServer = true
            e_sendRollToServer:FireServer(localRacer.id ,math.random(1,6)) 
        end
    end)
end

function self:ServerAwake()
    e_sendRollToServer:Connect(function(player,id, roll)
        e_sendRollToClients:FireAllClients(id,roll)
    end)
end

function StartMatch(gameIndex, p1,p2,firstTurn)
    racers = Racers()
    racers:Add(Racer(1,p1,firstTurn == 1))
    racers:Add(Racer(2,p2,firstTurn == 2))
    playerHud.SetRacers( racers )
    localRacer = racers:GetFromPlayer(client.localPlayer)
    boardGameObject:GetComponent("Board").Initialize(gameIndex,racers,p1,p2)
    diceTapHandler.gameObject:SetActive(racers.IsLocalRacerTurn())
end

function GetRacers()
    return racers
end