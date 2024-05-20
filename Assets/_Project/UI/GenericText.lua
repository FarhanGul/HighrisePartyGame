--!Type(UI)

--!Bind
local generic_text: UILabel = nil

function SetText(text)
    generic_text:SetPrelocalizedText(text, false)
end