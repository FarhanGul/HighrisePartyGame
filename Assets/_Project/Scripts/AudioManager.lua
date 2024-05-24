--!Type(Client)

--!SerializeField
local move : AudioSource = nil
--!SerializeField
local diceRoll : AudioSource = nil
--!SerializeField
local click : AudioSource = nil
--!SerializeField
local cardDraw : AudioSource = nil
--!SerializeField
local zap : AudioSource = nil
--!SerializeField
local nos : AudioSource = nil
--!SerializeField
local hit : AudioSource = nil
--!SerializeField
local raceStart : AudioSource = nil
--!SerializeField
local disconnect : AudioSource = nil
--!SerializeField
local resultNotify : AudioSource = nil
--!SerializeField
local honk : AudioSource = nil
--!SerializeField
local anomaly : AudioSource = nil
--!SerializeField
local teleport : AudioSource = nil
--!SerializeField
local damage : AudioSource = nil
--!SerializeField
local checkpoint : AudioSource = nil
--!SerializeField
local upgrade : AudioSource = nil
--!SerializeField
local flame : AudioSource = nil
--!SerializeField
local shield : AudioSource = nil
--!SerializeField
local hook : AudioSource = nil
--!SerializeField
local laser : AudioSource = nil

function PlayMove()
    move:Play()
end

function PlayDiceRoll()
    diceRoll:Play()
end

function PlayClick()
    click:Play()
end

function PlayCardDraw()
    cardDraw:Play()
end

function PlayZap()
    zap:Play()
end

function PlayNos()
    nos:Play()
end

function PlayHit()
    hit:Play()
end

function PlayRaceStart()
    raceStart:Play()
end

function PlayDisconnect()
    disconnect:Play()
end

function PlayResultNotify()
    resultNotify:Play()
end

function PlayHonk()
    honk:Play()
end

function PlayAnomaly()
    anomaly:Play()
end

function PlayTeleport()
    teleport:Play()
end

function PlayDamage()
    damage:Play()
end

function PlayCheckpoint()
    checkpoint:Play()
end

function PlayUpgrade()
    upgrade:Play()
end

function PlayFlame()
    flame:Play()
end

function PlayShield()
    shield:Play()
end

function PlayHook()
    hook:Play()
end

function PlayLaser()
    laser:Play()
end