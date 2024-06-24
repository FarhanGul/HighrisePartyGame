--!Type(Module)

-- Total Tiles 31
local tileConfigurations = {
    {
        -- 1 - A bit of everything
        Default = 10,
        Draw = 4,
        Mine = 2,
        Draw3 = 1,
        Burn = 2,
        Snare = 1,
        Recharge = 2,
        Draw2 = 2,
        Dome = 4,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 2 - Lots of cards and lot of burns
        Default = 8,
        Draw = 8,
        Mine = 2,
        Draw3 = 1,
        Burn = 4,
        Snare = 1,
        Recharge = 1,
        Draw2 = 2,
        Dome = 1,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 3 - Lots of mines and recharges
        Default = 9,
        Draw = 4,
        Mine = 4,
        Draw3 = 1,
        Snare = 1,
        Recharge = 5,
        Draw2 = 2,
        Dome = 2,
        Teleport = 2,
        Anomaly = 1
    },
    {
        -- 4 - Safe
        Default = 10,
        Draw = 8,
        Recharge = 2,
        Mine = 2,
        Draw2 = 2,
        Dome = 4,
        Teleport = 2,
        Anomaly = 1
    }
}

function GenerateRandomBoard()
    local randomConfigIndex = math.random(1,#tileConfigurations)
    -- randomConfigIndex = 2
    local randomConfig = tileConfigurations[randomConfigIndex]
    local teleportIndex1,teleportIndex2,anomalyIndex
    local usedIndices = {}
    if(randomConfig["Anomaly"] ~= nil) then
        anomalyIndex = GetRandomExcluding(16, 31, usedIndices)
        table.insert(usedIndices,anomalyIndex)
    end
    if(randomConfig["Teleport"] ~= nil) then
        -- generate index in middle
        local middleIndex = GetRandomExcluding(8, 22,usedIndices)
        -- Then generate teleport index
        teleportIndex1 = GetRandomExcluding(middleIndex - 6, middleIndex - 2,usedIndices)
        table.insert(usedIndices,teleportIndex1)
        teleportIndex2 = GetRandomExcluding(middleIndex + 2, middleIndex + 6,usedIndices)
        table.insert(usedIndices,teleportIndex2)
    end
    local remaingTiles = {}
    for k , v in pairs(randomConfig) do
        for i = 1, v do
            if ( k ~= "Anomaly" and k ~= "Teleport") then
                table.insert(remaingTiles,k)
            end
        end
    end
    for i = 1 , 5 do ShuffleArray(remaingTiles) end

    local finalBoard = {}
    for i = 1 , 31 do
        if ( i == teleportIndex1 or i == teleportIndex2) then
            finalBoard[i] = "Teleport"
        elseif ( i == anomalyIndex) then
            finalBoard[i] = "Anomaly"
        else
            finalBoard[i] = remaingTiles[1]
            table.remove(remaingTiles,1)
        end
    end
    return finalBoard
end

function ShuffleArray(arr)
    local n = #arr
    for i = n, 2, -1 do
        local j = math.random(i) -- Generate a random index
        arr[i], arr[j] = arr[j], arr[i] -- Swap elements
    end
end

function GetRandomExcluding(from, to, exclude)
    local rand = math.random(from , to)
    while( exclude[rand] ~= nil) do
        rand = math.random(from , to)
    end
    return rand
end

function ValidateTileConfigurations()
    for i =1 , #tileConfigurations do
        local _count = 0
        for k , v in pairs(tileConfigurations[i]) do
            _count += v
        end
        if(_count ~= 31) then
            print("Tile Validation for "..i.." Failed with count ".._count)
        end
    end
end