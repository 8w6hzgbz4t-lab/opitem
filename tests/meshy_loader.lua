-- Native Luau check. The runner supplies the three actual source strings:
-- {mock=<tools/roblox_mock.lua>, assets=<meshy/MeshyAssets.lua>,
--  loader=<meshy/MeshyModelLoader.lua>}. No Roblox network calls are simulated.
-- This tests assembly/security logic, not mesh quality or upload permissions.
return function(sources)
    local env = setmetatable({}, {__index=getfenv()})
    local function evaluate(source, name, environment)
        local chunk, err = loadstring(source, name)
        assert(chunk, err)
        setfenv(chunk, environment or env)
        return chunk()
    end
    local Mock = evaluate(assert(sources.mock), "@tools/roblox_mock.lua")
    local V, CF = env.Vector3, env.CFrame
    local checks = 0
    local function check(value, message)
        assert(value, message)
        checks += 1
    end
    local function near(a,b)
        return math.abs(a-b)<1e-5
    end
    local function rejects(callback, expected)
        local ok, result = pcall(callback)
        check(not ok and tostring(result):find(expected,1,true) ~= nil,
            "Expected "..expected..", got "..tostring(result))
    end

    -- Extend only this test's geometry mock with asset container features.
    local originalNew = env.Instance.new
    local sample = originalNew("Model")
    local mt = getmetatable(sample)
    local originalIndex = mt.__index
    mt.__index = function(instance,key)
        if key == "ClassName" then return instance._class end
        return originalIndex(instance,key)
    end
    local methods = {}
    -- The original __index closes over its own methods table. Install additional
    -- methods via this wrapper so the shared production mock stays untouched.
    local inheritedIndex = mt.__index
    mt.__index = function(instance,key)
        return methods[key] or inheritedIndex(instance,key)
    end
    env.Instance.new = function(class,parent)
        local supported = {Model=true,Folder=true,Part=true,MeshPart=true,WedgePart=true,CornerWedgePart=true}
        local instance = originalNew(supported[class] and class or "Folder")
        instance._class = class
        instance.Name = class
        instance.Parent = parent
        instance.Archivable = true
        return instance
    end
    function methods:GetAttributes() return table.clone(self._attrs) end
    function methods:GetChildren() return table.clone(self._children) end
    function methods:GetScale() return self._props._scale or 1 end
    function methods:GetPivot()
        return self.PrimaryPart and self.PrimaryPart.CFrame or self.WorldPivot or CF.new()
    end
    function methods:PivotTo(cf)
        local transform = cf*self:GetPivot():Inverse()
        for _, part in ipairs(self:GetDescendants()) do
            if part:IsA("BasePart") then part.CFrame = transform*part.CFrame end
        end
        self.WorldPivot = cf
    end
    function methods:ScaleTo(scale)
        local factor = scale/self:GetScale()
        local pivot = self:GetPivot()
        for _, part in ipairs(self:GetDescendants()) do
            if part:IsA("BasePart") then
                local localCF = pivot:ToObjectSpace(part.CFrame)
                part.CFrame = pivot*CF.new(localCF.Position*factor)*localCF.Rotation
                part.Size *= factor
            end
        end
        self._props._scale = scale
    end
    function methods:Clone()
        local remap = {}
        local function copy(original)
            local clone = env.Instance.new(original.ClassName)
            remap[original] = clone
            for key,value in pairs(original._props) do
                if key ~= "Parent" and key ~= "PrimaryPart" then clone[key] = value end
            end
            clone._attrs = table.clone(original._attrs)
            clone._tags = original._tags and table.clone(original._tags) or nil
            for _, child in ipairs(original:GetChildren()) do copy(child).Parent = clone end
            return clone
        end
        local result = copy(self)
        for original,clone in pairs(remap) do
            if original.PrimaryPart then clone.PrimaryPart = remap[original.PrimaryPart] end
        end
        return result
    end

    local actualConfig = evaluate(assert(sources.assets), "@meshy/MeshyAssets.lua")
    local configuredCount = 0
    for key, entry in pairs(actualConfig) do
        check(entry.AssetId == 0, key.." must not contain a fabricated asset ID")
        check(entry.TargetHeight > 0 and entry.MaxSpan > 0, key.." needs positive dimensions")
        check(entry.Orientation ~= nil and entry.Collidable == false, key.." needs safe visual defaults")
        configuredCount += 1
    end
    check(configuredCount == 33, "All 33 requested model components must have whitelist entries")
    check(actualConfig.blue_shell.ItemId == "item05", "Blue Shell must retain item05")
    check(actualConfig.dragon_balls.ItemId == "item43", "Dragon Balls must retain item43")
    check(actualConfig.hooh_wing_left.PivotMode == "preserve", "Wing hinge origin must be preserved")

    local fixture = env.Instance.new("Model")
    fixture:SetAttribute("Untrusted",true)
    fixture._tags = {"UntrustedTag"}
    local nested = env.Instance.new("Model",fixture)
    local mesh = env.Instance.new("MeshPart",nested)
    mesh.Name = "ImportedMesh"
    mesh.Size = V.new(20,40,10)
    mesh.CFrame = CF.new(24,75,-30)
    mesh.TextureID = "rbxassetid://111"
    mesh:SetAttribute("OriginalUnsafeAttribute",true)
    mesh._tags = {"UntrustedTag"}
    local pbr = env.Instance.new("SurfaceAppearance",mesh)
    pbr.ColorMap = "rbxassetid://222"
    pbr.NormalMap = "rbxassetid://333"
    pbr.RoughnessMap = "rbxassetid://444"
    pbr.MetalnessMap = "rbxassetid://555"
    env.Instance.new("Decal",mesh).Texture = "rbxassetid://666"
    for _, class in ipairs({"Script","LocalScript","ModuleScript","RemoteEvent","RemoteFunction", "BindableEvent","BindableFunction","Humanoid","ProximityPrompt","Seat","WeldConstraint","Sound"}) do
        env.Instance.new(class,nested)
    end
    -- A MeshPart hidden under a disallowed object must disappear with that tree.
    local tool = env.Instance.new("Tool",fixture)
    env.Instance.new("MeshPart",tool).Name = "HiddenUnderTool"

    local loadCalls = 0
    local insert = {}
    function insert:LoadAsset(id)
        loadCalls += 1
        check(id == 123 or id == 124 or id == 125, "Only whitelisted numeric IDs can reach InsertService")
        if id == 125 then error("asset permissions denied") end
        if id == 124 then return env.Instance.new("Model") end
        return fixture:Clone()
    end
    local collection = {}
    function collection:GetTags(instance) return table.clone(instance._tags or {}) end
    function collection:RemoveTag(instance,tag)
        for index,value in ipairs(instance._tags or {}) do
            if value == tag then table.remove(instance._tags,index); break end
        end
    end
    env.game = {GetService=function(_,name)
        if name == "InsertService" then return insert end
        if name == "CollectionService" then return collection end
        error("Unexpected service "..name)
    end}
    local testConfig = {
        blue_shell={AssetId=123,Name="Blue Shell",ItemId="item05",TargetHeight=4,MaxSpan=5.5},
        wide={AssetId=123,TargetHeight=10,MaxSpan=3,Orientation=CF.Angles(0,0,math.pi/2)},
        centered={AssetId=123,TargetHeight=4,MaxSpan=5.5,PivotMode="center"},
        hinge={AssetId=123,TargetHeight=4,MaxSpan=5.5,PivotMode="preserve"},
        missing={AssetId=0,TargetHeight=4,MaxSpan=5.5},
        empty={AssetId=124,TargetHeight=4,MaxSpan=5.5},
        denied={AssetId=125,TargetHeight=4,MaxSpan=5.5},
        budget={AssetId=123,TargetHeight=4,MaxSpan=5.5,MaxParts=0},
    }
    local sentinel = {}
    env.script = {Parent={MeshyAssets=sentinel}}
    env.require = function(target)
        assert(target == sentinel, "Unexpected module require")
        return testConfig
    end
    local Loader = evaluate(assert(sources.loader), "@meshy/MeshyModelLoader.lua")
    check(Loader.isConfigured("blue_shell"), "Configured asset should be reported")
    check(not Loader.isConfigured("missing") and not Loader.isConfigured("unknown"), "Unknown/zero IDs are unconfigured")
    rejects(function() Loader.create("missing") end, "NOT_CONFIGURED")
    rejects(function() Loader.create("unknown") end, "UNKNOWN_KEY")
    rejects(function() Loader.create("blue_shell",nil,{AssetId=999}) end, "UNTRUSTED_ID")
    rejects(function() Loader.create("blue_shell",nil,{itemId="item08"}) end, "ITEM_ID_MISMATCH")
    rejects(function() Loader.create("blue_shell",nil,{scale=0}) end, "INVALID_OPTIONS")
    rejects(function() Loader.create("blue_shell",nil,{scale=0/0}) end, "INVALID_OPTIONS")
    rejects(function() Loader.create("blue_shell",nil,{cframe="not a transform"}) end, "INVALID_OPTIONS")
    check(loadCalls == 0, "Invalid requests must fail before InsertService is called")

    local destination = env.Instance.new("Folder")
    local model = Loader.create("blue_shell",destination,{name="Display shell",itemId="item05"})
    check(model.Parent == destination and model.Name == "Display shell", "Final parent/name must be applied")
    check(model:GetAttribute("Kind") == "item05" and model.PrimaryPart:GetAttribute("Kind") == "item05", "Canonical item ID must survive")
    local root = model.PrimaryPart
    check(root.Name == "Root" and root.Transparency == 1 and near(root.Size.X,.1), "A small invisible pivot must exist")
    check(root.Anchored and not root.CanCollide and not root.CanQuery and not root.CanTouch, "Root must be noninteractive")
    local kept = model:FindFirstChild("ImportedMesh",true)
    check(kept ~= nil and kept.Anchored and not kept.CanCollide and not kept.CanTouch and not kept.CanQuery, "Mesh must be safe anchored visual geometry")
    check(kept:GetAttribute("OriginalUnsafeAttribute") == nil and #collection:GetTags(kept) == 0, "Imported attributes and tags must be removed")
    check(model:FindFirstChild("HiddenUnderTool",true) == nil, "Disallowed subtrees must be removed")
    for _, descendant in ipairs(model:GetDescendants()) do
        check(not descendant:IsA("Script") and not descendant:IsA("LocalScript") and not descendant:IsA("ModuleScript"), "No imported code may remain")
        check(descendant.ClassName ~= "RemoteEvent" and descendant.ClassName ~= "Humanoid", "No behavior instances may remain")
    end
    local appearance = kept:FindFirstChild("SurfaceAppearance")
    check(appearance and appearance.NormalMap == "rbxassetid://333" and appearance.MetalnessMap == "rbxassetid://555", "PBR maps must be preserved")
    check(kept.TextureID == "rbxassetid://111" and kept:FindFirstChild("Decal").Texture == "rbxassetid://666", "Texture references must be preserved")
    local low,high = Mock.bounds(model)
    check(near(low.Y,.04) and near(high.Y-low.Y,4), "Display geometry must fit its target height and align above pivot")
    check(near(low.X+high.X,0) and near(low.Z+high.Z,0), "Display geometry must be horizontally centered")
    check(loadCalls == 1, "First create must load one asset")
    kept.Name = "Changed only this clone"
    local clone = Loader.create("blue_shell",nil,{scale=2,cframe=CF.new(10,20,30)})
    check(loadCalls == 1 and clone:FindFirstChild("ImportedMesh",true) ~= nil, "Cached templates must be reused and isolated from clones")
    check(near(clone.PrimaryPart.Position.X,10) and near(clone.PrimaryPart.Position.Y,20), "Requested display transform must be applied")
    local a,b = Mock.bounds(clone)
    check(near(b.Y-a.Y,8), "Optional uniform scale must be applied once")
    local wide = Loader.create("wide")
    a,b = Mock.bounds(wide)
    check(math.max(b.X-a.X,b.Z-a.Z) <= 3+1e-5, "Rotated imports must obey MaxSpan")
    local centered = Loader.create("centered")
    a,b = Mock.bounds(centered)
    check(near(a.Y+b.Y,0), "Center pivot must align around geometric center")
    local hinge = Loader.create("hinge")
    local hingeMesh = hinge:FindFirstChild("ImportedMesh",true)
    check(near(hingeMesh.Position.X,2.4) and near(hingeMesh.Position.Y,7.5), "Authored hinge origin must survive scale without centering")
    rejects(function() Loader.create("empty") end, "EMPTY_ASSET")
    rejects(function() Loader.create("denied") end, "permissions denied")
    rejects(function() Loader.create("budget") end, "PART_BUDGET")
    local before = loadCalls
    Loader.clearCache("blue_shell")
    check(Loader.preload("blue_shell") and loadCalls == before+1, "Clearing/preloading must refresh only the configured template")
    Loader.clearCache()
    return string.format("%d checks: 33 unconfigured assets, whitelisted loads, scrubbed behavior, preserved PBR, bounds/pivots, caching, failures",checks)
end
