--!Type(Client)

--!SerializeField
local move : AudioSource = nil
--!SerializeField
local diceRoll : AudioSource = nil
--!SerializeField
local click : AudioSource = nil

function PlayMove()
    move:Play()
end

function PlayDiceRoll()
    diceRoll:Play()
end

function PlayClick()
    click:Play()
end