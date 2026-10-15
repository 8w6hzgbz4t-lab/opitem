-- Install before collectible templates are built. Replaces visual construction only.
-- Original item definitions, economy, transactions, and Millennium Puzzle remain intact.
local FreeModels = require(script.Parent.FreeModels)
local M = {}
local installed = setmetatable({}, {__mode="k"})
local replacements = {item05="blue_shell",item43="dragon_balls"}

function M.install(factory)
    assert(type(factory)=="table" and type(factory.create)=="function", "A ModelFactory table is required")
    if installed[factory] then return factory end
    local originalCreate = factory.create
    factory.create = function(definition, parent)
        -- The existing, approved Millennium Puzzle must always use its original builder.
        if definition.id == "item08" then return originalCreate(definition, parent) end
        local key = replacements[definition.id] or definition.model
        if FreeModels.supports(key) then
            return FreeModels.create(parent, {model=key,itemId=definition.id,name=definition.name})
        end
        return originalCreate(definition, parent)
    end
    installed[factory] = true
    return factory
end

return M
