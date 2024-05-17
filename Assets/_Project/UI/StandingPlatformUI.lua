--!Type(UI)

--!Bind
local root: VisualElement = nil

function self:ClientAwake()
    root:Q("test"):SetPrelocalizedText("Player name", false)
end