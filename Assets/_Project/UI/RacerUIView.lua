--!Type(UI)

--!Bind
local usernames: VisualElement = nil

function SetPlayer(id,racer)
    local usernameBlock = usernames:Q("userblock_"..id)
    if (racer == nil) then
        usernameBlock.visible = false
        return
    end
    usernameBlock.visible = true
    usernameBlock:Q("username_"..id):SetPrelocalizedText(racer.player.name, false)
    usernameBlock:Q("turn_indicator_"..id).visible = racer.isTurn
end
