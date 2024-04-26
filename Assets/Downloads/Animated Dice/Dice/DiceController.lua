--!SerializeField
local DiceMesh : GameObject = nil

local rotateCubeEvent = Event.new("RotateCubeEvent")
local diceState = IntValue.new("DiceState")

function Client()

    function rotateCubeRandomly(randomFace)

        local rotation = Vector3.new(0,0,0)
        local x, y, z = 0, 0, 0

        if (randomFace == 1) then
            -- Up
            x = 0
            y = 0
            z = 0
        elseif (randomFace == 2) then
            -- Down
            x = 180
            y = 0
            z = 0
        elseif (randomFace == 3) then
            -- Right
            x = 0
            y = 0
            z = 90
        elseif (randomFace == 4) then
            -- Left
            x = 0
            y = 0
            z = -90
        elseif (randomFace == 5) then
            -- Front
            x = 90
            y = 0
            z = 0
        elseif (randomFace == 6) then
            -- Back
            x = -90
            y = 0
            z = 0
        end
    
        -- Apply rotation to the cube
        rotation = Vector3.new(x,y,z)
        DiceMesh.transform.eulerAngles = rotation
        self.gameObject:GetComponent(Animator):SetTrigger("Flip")
    end

    self.transform.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        rotateCubeEvent:FireServer()
        self.gameObject:GetComponent(AudioSource):Play()
    end)

    diceState.Changed:Connect(function(newVal, oldVal)
        rotateCubeRandomly(newVal)
    end)
end

function Server()
    rotateCubeEvent:Connect(function()
        diceState.value = math.random(1, 6)
    end)

end

if server then
    Server()
else
    Client()
end