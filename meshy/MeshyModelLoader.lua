-- Server-only importer for assets you exported from Meshy, imported with Studio's
-- 3D Importer, and uploaded to Roblox as Models. Keep this beside MeshyAssets in
-- ServerScriptService or ServerStorage. This module does not call Meshy itself.
-- Never expose create() through a remote that accepts a client-supplied asset ID.
local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")
local Assets = require(script.Parent.MeshyAssets)

local Loader = {}
local templates = {}
local loading = {}

-- Keep geometry, its hierarchy, and render data only. Scripts, remotes, prompts,
-- Humanoids, seats, constraints, lights, sounds, and imported UI are not retained.
local allowed = {
    Model = true, Folder = true,
    Part = true, MeshPart = true, WedgePart = true, CornerWedgePart = true,
    UnionOperation = true,
    SurfaceAppearance = true, SpecialMesh = true, BlockMesh = true,
    CylinderMesh = true, Decal = true, Texture = true,
}

local function fail(code, key, message)
    error(string.format("MeshyModelLoader [%s] %s: %s", code, tostring(key), message), 3)
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function entryFor(key)
    if type(key) ~= "string" or not Assets[key] then
        fail("UNKNOWN_KEY", key, "add the asset key to the server-owned MeshyAssets whitelist")
    end
    return Assets[key]
end

local function checkedId(key, entry)
    local id = entry.AssetId
    if id == 0 then
        fail("NOT_CONFIGURED", key,
            "import the generated GLB/FBX in Studio, upload it as your own Roblox Model, and put its numeric Model asset ID in MeshyAssets")
    end
    if not finite(id) or id < 1 or id % 1 ~= 0 then
        fail("INVALID_ASSET_ID", key, "AssetId must be a positive integer Roblox Model asset ID")
    end
    return id
end

local function clearMetadata(instance)
    for name in pairs(instance:GetAttributes()) do instance:SetAttribute(name, nil) end
    for _, tag in ipairs(CollectionService:GetTags(instance)) do
        CollectionService:RemoveTag(instance, tag)
    end
end

local function sanitize(container, key, entry)
    local parts = {}
    local function walk(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if not allowed[child.ClassName] then
                child:Destroy()
            else
                clearMetadata(child)
                child.Archivable = true
                if child:IsA("BasePart") then
                    if not finite(child.Size.X) or not finite(child.Size.Y)
                        or not finite(child.Size.Z) or child.Size.X <= 0
                        or child.Size.Y <= 0 or child.Size.Z <= 0 then
                        fail("INVALID_GEOMETRY", key, "a part has a non-finite or empty size")
                    end
                    child.Anchored = true
                    child.CanCollide = entry.Collidable == true
                    child.CanQuery = entry.Collidable == true
                    child.CanTouch = false
                    child.Massless = true
                    child.AssemblyLinearVelocity = Vector3.zero
                    child.AssemblyAngularVelocity = Vector3.zero
                    table.insert(parts, child)
                end
                walk(child)
            end
        end
    end
    walk(container)
    if #parts == 0 then fail("EMPTY_ASSET", key, "the uploaded Model contains no supported geometry") end
    local maxParts = entry.MaxParts or 600
    if #parts > maxParts then
        fail("PART_BUDGET", key, string.format("%d parts exceeds the configured limit of %d", #parts, maxParts))
    end
    return parts
end

-- Explicit world-space bounds remain correct for rotated or nested MeshParts.
-- A transparent imported helper part should be removed in Studio before upload.
local function bounds(parts, key)
    local low = Vector3.new(math.huge, math.huge, math.huge)
    local high = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, part in ipairs(parts) do
        local half = part.Size * .5
        for _, x in ipairs({-1, 1}) do
            for _, y in ipairs({-1, 1}) do
                for _, z in ipairs({-1, 1}) do
                    local p = part.CFrame:PointToWorldSpace(Vector3.new(half.X*x, half.Y*y, half.Z*z))
                    if not finite(p.X) or not finite(p.Y) or not finite(p.Z) then
                        fail("INVALID_GEOMETRY", key, "a part has a non-finite transform")
                    end
                    low = Vector3.new(math.min(low.X,p.X), math.min(low.Y,p.Y), math.min(low.Z,p.Z))
                    high = Vector3.new(math.max(high.X,p.X), math.max(high.Y,p.Y), math.max(high.Z,p.Z))
                end
            end
        end
    end
    return low, high
end

local function buildTemplate(key, entry, assetId)
    local source
    local model
    local ok, result = pcall(function()
        source = InsertService:LoadAsset(assetId)
        if not source or typeof(source) ~= "Instance" then
            fail("LOAD_FAILED", key, "InsertService returned no Model; check ownership and asset permissions")
        end
        -- LoadAsset returns an unparented container. Scrub it before anything is
        -- ever parented to the game. Loading permission is controlled by Roblox.
        source.Parent = nil
        clearMetadata(source)
        local parts = sanitize(source, key, entry)
        model = Instance.new("Model")
        model.Name = entry.Name or key
        model.Archivable = true
        for _, child in ipairs(source:GetChildren()) do child.Parent = model end
        source:Destroy()
        source = nil

        local orientation = entry.Orientation or CFrame.new()
        if typeof(orientation) ~= "CFrame" then
            fail("INVALID_CONFIG", key, "Orientation must be a CFrame")
        end
        -- Transform the imported coordinates directly so optional shoulder/tail
        -- origins survive. A Model's automatically computed pivot is its bounds
        -- center and would otherwise discard a deliberately offset hinge.
        for _, part in ipairs(parts) do part.CFrame = orientation * part.CFrame end
        model.WorldPivot = CFrame.new()
        local low, high = bounds(parts, key)
        local size = high - low
        local height = entry.TargetHeight
        local span = entry.MaxSpan
        if not finite(height) or height <= 0 or not finite(span) or span <= 0 then
            fail("INVALID_CONFIG", key, "TargetHeight and MaxSpan must be positive finite numbers")
        end
        local factor = math.min(height/size.Y, span/math.max(size.X,size.Z))
        model:ScaleTo(factor)
        low, high = bounds(parts, key)
        local mode = entry.PivotMode or "bottom"
        local offset
        if mode == "bottom" then
            offset = Vector3.new(-(low.X+high.X)*.5, .04-low.Y, -(low.Z+high.Z)*.5)
        elseif mode == "center" then
            offset = -(low+high)*.5
        elseif mode == "preserve" then
            offset = Vector3.zero
        else
            fail("INVALID_CONFIG", key, "PivotMode must be bottom, center, or preserve")
        end
        model:PivotTo(CFrame.new(offset) * model:GetPivot())

        local root = Instance.new("Part")
        root.Name = "Root"
        root.Size = Vector3.new(.1,.1,.1)
        root.CFrame = CFrame.new()
        root.Anchored = true
        root.Transparency = 1
        root.CanCollide = false
        root.CanQuery = false
        root.CanTouch = false
        root.Massless = true
        root.Parent = model
        model.PrimaryPart = root
        model:SetAttribute("MeshyAssetKey", key)
        model:SetAttribute("MeshyAssetId", assetId)
        model:SetAttribute("ArtSource", "MeshyImported")
        model:SetAttribute("PartCount", #parts)
        model:SetAttribute("AnimatedCharacter", false)
        local kind = entry.ItemId or key
        model:SetAttribute("Kind", kind)
        root:SetAttribute("Kind", kind)
        return model
    end)
    if not ok then
        if source then source:Destroy() end
        if model then model:Destroy() end
        fail("LOAD_FAILED", key, tostring(result)..". Check Model ownership, permissions, and the imported geometry")
    end
    return result
end

function Loader.isConfigured(key)
    local entry = Assets[key]
    return entry ~= nil and finite(entry.AssetId) and entry.AssetId >= 1 and entry.AssetId % 1 == 0
end

-- Call from a server-owned item factory. This never changes prices, rarity,
-- income, inventories, progression, or catalog entries.
function Loader.create(key, parent, options)
    options = options or {}
    local entry = entryFor(key)
    if options.assetId ~= nil or options.AssetId ~= nil then
        fail("UNTRUSTED_ID", key, "asset IDs belong only in the server-owned MeshyAssets whitelist")
    end
    local assetId = checkedId(key, entry)
    local scale = options.scale or 1
    if not finite(scale) or scale <= 0 or scale > 100 then
        fail("INVALID_OPTIONS", key, "scale must be greater than zero and at most 100")
    end
    if options.cframe ~= nil and typeof(options.cframe) ~= "CFrame" then
        fail("INVALID_OPTIONS", key, "cframe must be a CFrame")
    end
    local itemId = options.itemId or entry.ItemId or key
    if entry.ItemId and itemId ~= entry.ItemId then
        fail("ITEM_ID_MISMATCH", key, "use the existing catalog ID "..entry.ItemId)
    end
    if type(itemId) ~= "string" or #itemId == 0 or #itemId > 100 then
        fail("INVALID_OPTIONS", key, "itemId must be a non-empty string of at most 100 characters")
    end
    if options.name ~= nil and (type(options.name) ~= "string" or #options.name == 0 or #options.name > 100) then
        fail("INVALID_OPTIONS", key, "name must be a non-empty string of at most 100 characters")
    end
    if not templates[key] then
        if loading[key] then
            fail("LOAD_IN_PROGRESS", key, "a load for this key is already running; preload once before spawning")
        end
        loading[key] = true
        local ok, result = pcall(buildTemplate, key, entry, assetId)
        loading[key] = nil
        if not ok then error(result, 2) end
        templates[key] = result
    end
    local model = templates[key]:Clone()
    model.Name = options.name or entry.Name or key
    if scale ~= 1 then model:ScaleTo(model:GetScale()*scale) end
    model:SetAttribute("Kind", itemId)
    model.PrimaryPart:SetAttribute("Kind", itemId)
    model:PivotTo(options.cframe or CFrame.new())
    model.Parent = parent
    return model
end

-- Optional boot-time preload. Failed IDs raise errors instead of substituting a
-- placeholder. Do this once before a busy conveyor starts spawning items.
function Loader.preload(key)
    local clone = Loader.create(key, nil)
    clone:Destroy()
    return true
end

-- Clear this after editing a configured ID during a Studio session.
function Loader.clearCache(key)
    if key then
        entryFor(key)
        if templates[key] then templates[key]:Destroy(); templates[key] = nil end
    else
        for cacheKey, template in pairs(templates) do
            template:Destroy()
            templates[cacheKey] = nil
        end
    end
end

return Loader
