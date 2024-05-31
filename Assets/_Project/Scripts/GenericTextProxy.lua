--!Type(Client)

--!SerializeField
local meshRenderer : MeshRenderer = nil

function self:ClientOnEnable()
    meshRenderer.enabled = true
end

function self:ClientOnDisable()
    meshRenderer.enabled = false
end