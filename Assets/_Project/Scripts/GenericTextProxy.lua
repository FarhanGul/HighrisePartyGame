--!Type(Client)

-- Does not move

--!SerializeField
local meshRenderer : MeshRenderer = nil

function self:ClientOnEnable()
    meshRenderer.enabled = true
    -- print(tostring(meshRenderer.transform.position ))
    -- print(tostring(self.transform.position ))
end

function self:ClientOnDisable()
    meshRenderer.enabled = false
end

function self:ClientUpdate()
    meshRenderer.transform.position = self.transform.position
end
