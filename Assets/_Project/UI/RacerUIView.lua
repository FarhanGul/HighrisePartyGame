--!Type(UI)

--!Bind
local _player_1 : UILabel = nil
--!Bind
local _player_2 : UILabel = nil

function Test(userName, userScore)
    _player_1:SetPrelocalizedText("test Name", false)
    _player_2:SetPrelocalizedText("Test score", false)
end