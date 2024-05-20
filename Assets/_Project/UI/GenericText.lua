--!Type(UI)

--!SerializeField
local isHeading: boolean = false

--!Bind
local generic_text: UILabel = nil

function self:ClientAwake()
    -- SetText("IT'S YOUR OPPONENT'S TURN")
end

function SetText(text)
    generic_text:EnableInClassList("heading_text",isHeading)
    generic_text:EnableInClassList("normal_text",not isHeading)
    generic_text:SetPrelocalizedText(text, false)
end