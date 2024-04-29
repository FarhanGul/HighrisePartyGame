--!Type(UI)

--!Bind
local usernames: VisualElement = nil

function SetPlayer(id,player)
    local usernameBlock = usernames:Q("player_"..id)
    if (player == nil) then
        usernameBlock.visible = false
        return
    end
    usernameBlock.visible = true
    usernameBlock:Q("l_"..id):SetPrelocalizedText(player.player.name, false)
    usernameBlock:Q("t_"..id).visible = player.isTurn
end
