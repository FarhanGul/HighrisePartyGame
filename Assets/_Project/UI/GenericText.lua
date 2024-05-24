--!Type(UI)

--!SerializeField
local isHeading: boolean = false
--!SerializeField
local isSmall: boolean = false
--!SerializeField
local isTiny: boolean = false
--!SerializeField
local label: string = ""

--!Bind
local generic_text: UILabel = nil

function self:ClientAwake()
    -- SetText("FarhanGulDev Played AntimatterCannon but was blocked")
    if(label ~= "") then SetText(label) end
    UpdateStyling()
end

function SetText(text)
    UpdateStyling()
    generic_text:SetPrelocalizedText(text, false)
end

function UpdateStyling()
    generic_text:EnableInClassList("heading_text",isHeading)
    generic_text:EnableInClassList("normal_text",not isHeading and not isSmall and not isTiny)
    generic_text:EnableInClassList("small_text",isSmall)
    generic_text:EnableInClassList("tiny_text",isTiny)
end