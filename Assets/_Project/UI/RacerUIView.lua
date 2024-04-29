--!Type(UI)

--!Bind
local usernames: VisualElement = nil

function SetPlayer(id,player)
    local usernameBlock = usernames:Q("userblock_"..id)
    if (player == nil) then
        usernameBlock.visible = false
        return
    end
    usernameBlock.visible = true
    usernameBlock:Q("username_"..id):SetPrelocalizedText(player.player.name, false)
    usernameBlock:Q("turn_indicator_"..id).visible = player.isTurn
end
