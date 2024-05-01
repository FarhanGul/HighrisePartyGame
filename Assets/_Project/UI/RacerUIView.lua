--!Type(UI)

--!Bind
local usernames: VisualElement = nil
--!Bind
local scene_heading_group: VisualElement = nil
--!Bind
local scene_help_group: VisualElement = nil

function SetPlayer(id,racer)
    if (racer == nil) then
        usernames:Q("username_"..id).visible = false
        usernames:Q("turn_indicator_"..id).visible = false
        return
    end
    usernames:Q("username_"..id).visible = true
    usernames:Q("username_"..id):SetPrelocalizedText(racer.player.name, false)
    usernames:Q("turn_indicator_"..id).visible = racer.isTurn
end

function SetSceneHeading(title,subtitle)
    if (title == nil or subtitle == nil) then
        scene_heading_group.visible = false
        return
    end
    scene_heading_group.visible = true
    scene_heading_group:Q("scene_title"):SetPrelocalizedText(title, false)
    scene_heading_group:Q("scene_subtitle"):SetPrelocalizedText(subtitle, false)
end

function SetSceneHelp(help)
    if (help == nil) then
        scene_help_group.visible = false
        return
    end
    scene_help_group.visible = true
    scene_help_group:Q("scene_help"):SetPrelocalizedText(help, false)
end
