-- Optional visual-only hook. Install beside MeshyModelLoader and MeshyAssets.
-- Call once from trusted server startup. Existing visuals remain the fallback
-- until a real imported Model ID is configured. Catalog stats stay untouched.
local Loader = require(script.Parent.MeshyModelLoader)
local Assets = require(script.Parent.MeshyAssets)
local Integration = {}
local knownIds = {item05 = "blue_shell", item43 = "dragon_balls"}
local warned = {}

function Integration.install(factory, additionalIds)
    assert(type(factory) == "table" and type(factory.create) == "function", "Expected the existing model factory")
    local original = factory.create
    local byId = table.clone(knownIds)
    for id, key in pairs(additionalIds or {}) do
        assert(type(id) == "string" and Assets[key], "Map a real catalog ID to a known Meshy asset key")
        byId[id] = key
    end
    factory.create = function(definition, parent)
        local key = byId[definition.id]
        if key and Loader.isConfigured(key) then
            local ok, model = pcall(Loader.create, key, parent, {
                itemId = definition.id, name = definition.name,
            })
            if ok then return model end
            if not warned[key] then
                warned[key] = true
                warn("Meshy visual unavailable for "..key.."; using the existing model. "..tostring(model))
            end
        end
        return original(definition, parent)
    end
    return factory
end

return Integration
