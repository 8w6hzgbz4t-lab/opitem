local MillenniumPuzzle = {}

local GOLD = Color3.fromRGB(213, 157, 45)
local LIGHT_GOLD = Color3.fromRGB(248, 208, 106)
local EDGE_GOLD = Color3.fromRGB(179, 117, 30)
local SEAM = Color3.fromRGB(87, 51, 15)
local EYE_DARK = Color3.fromRGB(42, 27, 11)
local METAL = Enum.Material.Metal

function MillenniumPuzzle.create(parent, options)
    options = options or {}
    local scale = options.scale or 1
    assert(type(scale) == "number" and scale > 0 and scale < math.huge,
        "MillenniumPuzzle scale must be a finite positive number")
    local model = Instance.new("Model")
    model.Name = options.name or "MillenniumPuzzle"
    model:SetAttribute("Kind", options.itemId or "millennium_puzzle")
    model:SetAttribute("ItemId", options.itemId or "millennium_puzzle")
    model:SetAttribute("Procedural", true)
    model:SetAttribute("AnimatedCharacter", false)
    model:SetAttribute("Scale", scale)
    local partCount = 0
    local function vec(x, y, z)
        return Vector3.new(x, y, z) * scale
    end
    local function part(name, size, frame, color, shape)
        local object = Instance.new("Part")
        object.Name = name
        object.Size = size
        object.CFrame = frame
        object.Color = color or GOLD
        object.Material = METAL
        object.Shape = shape or Enum.PartType.Block
        object.Anchored = true
        object.CanCollide = false
        object.CanTouch = false
        object.CanQuery = false
        object.TopSurface = Enum.SurfaceType.Smooth
        object.BottomSurface = Enum.SurfaceType.Smooth
        object.Parent = model
        partCount = partCount + 1
        return object
    end
    local function line(name, a, b, thickness, depth, color)
        local delta = b - a
        if delta.Magnitude < 0.000001 then return nil end
        local up = delta.Unit
        local reference = Vector3.new(0, 0, 1)
        if math.abs(up:Dot(reference)) > 0.95 then
            reference = Vector3.new(1, 0, 0)
        end
        local right = up:Cross(reference).Unit
        local back = right:Cross(up).Unit
        return part(name,
            Vector3.new(thickness * scale, delta.Magnitude, depth * scale),
            CFrame.fromMatrix((a + b) * 0.5, right, up, back), color)
    end
    local root = part("Root", vec(0.12, 0.12, 0.12), CFrame.new(), GOLD)
    root.Transparency = 1
    model.PrimaryPart = root
    local width = 3.1
    local height = 3.3
    local topY = 1.0
    local bottomY = topY - height
    local layerCount = 24
    local step = height / layerCount
    for index = 1, layerCount do
        local t = (index - 0.5) / layerCount
        local layerWidth = width * t
        local y = bottomY + step * (index - 0.5)
        part(string.format("GoldCourse_%02d", index),
            vec(layerWidth, step + 0.002, layerWidth),
            CFrame.new(vec(0, y, 0)), GOLD)
    end
    part("BottomFinial", vec(0.074, 0.16, 0.074),
        CFrame.new(vec(0, bottomY + 0.008, 0)), LIGHT_GOLD, Enum.PartType.Ball)
    part("TopPlate", vec(width + 0.04, 0.12, width + 0.04),
        CFrame.new(vec(0, topY, 0)), EDGE_GOLD)
    part("TopInset", vec(width - 0.24, 0.038, width - 0.24),
        CFrame.new(vec(0, topY + 0.079, 0)), GOLD)
    local half = width * 0.5
    for index = 1, 4 do
        local angle = (index - 1) * math.pi * 0.5
        local frame = CFrame.new(vec(0, topY + 0.092, 0))
            * CFrame.Angles(0, angle, 0)
            * CFrame.new(vec(0, 0, -half + 0.06))
        part("TopRim_" .. index, vec(width - 0.08, 0.07, 0.075), frame, LIGHT_GOLD)
    end
    for _, xSign in ipairs({ -1, 1 }) do
        for _, zSign in ipairs({ -1, 1 }) do
            local suffix = tostring(xSign) .. "_" .. tostring(zSign)
            line("CornerBinding_" .. suffix,
                vec(0, bottomY + 0.02, 0), vec(xSign * half, topY, zSign * half),
                0.052, 0.052, EDGE_GOLD)
            part("CornerStud_" .. suffix, vec(0.14, 0.075, 0.14),
                CFrame.new(vec(xSign * (half - 0.12), topY + 0.11,
                    zSign * (half - 0.12))), LIGHT_GOLD, Enum.PartType.Ball)
        end
    end
    local function facePoint(x, y, outward)
        local side = math.max(0.025, half * ((y - bottomY) / height))
        return vec(x, y, -side - (outward or 0.04))
    end
    local seamRows = { -1.65, -1.08, -0.51, 0.06, 0.63 }
    for face = 0, 3 do
        local rotation = CFrame.Angles(0, face * math.pi * 0.5, 0)
        for row, y in ipairs(seamRows) do
            local side = half * ((y - bottomY) / height)
            local a = rotation * facePoint(-side + 0.035, y, 0.028)
            local b = rotation * facePoint(side - 0.035, y, 0.028)
            line("PanelRow_" .. face .. "_" .. row, a, b, 0.021, 0.015, SEAM)
        end
        for index = 1, 4 do
            local lowerY = seamRows[index] + 0.035
            local upperY = seamRows[index + 1] - 0.035
            local lowerHalf = half * ((lowerY - bottomY) / height)
            local upperHalf = half * ((upperY - bottomY) / height)
            local fraction = index % 2 == 0 and -0.34 or 0.34
            line("PanelJoin_" .. face .. "_" .. index,
                rotation * facePoint(lowerHalf * fraction, lowerY, 0.033),
                rotation * facePoint(upperHalf * fraction, upperY, 0.033),
                0.021, 0.015, SEAM)
        end
    end
    local eyeY = -0.11
    local eyeHalfWidth = 0.77
    local function eyePoint(x, y, offset)
        return facePoint(x, eyeY + y, offset or 0.082)
    end
    local function eyeStroke(name, points, color, thickness)
        for index = 1, #points - 1 do
            local a = points[index]
            local b = points[index + 1]
            line(name .. "_" .. index, eyePoint(a[1], a[2]),
                eyePoint(b[1], b[2]), thickness or 0.06, 0.048, color)
        end
    end
    local upper = {}
    local lower = {}
    for index = 0, 8 do
        local t = index / 8
        local x = -eyeHalfWidth + 2 * eyeHalfWidth * t
        upper[#upper + 1] = { x, 0.21 * math.sin(math.pi * t) }
        lower[#lower + 1] = { x, -0.19 * math.sin(math.pi * t) }
    end
    eyeStroke("EyeUpper", upper, LIGHT_GOLD, 0.075)
    eyeStroke("EyeLower", lower, LIGHT_GOLD, 0.075)
    eyeStroke("EyeBrow", {
        { -0.82, 0.22 }, { -0.60, 0.33 }, { -0.29, 0.40 },
        { 0.04, 0.43 }, { 0.38, 0.37 }, { 0.68, 0.25 }, { 0.91, 0.22 },
    }, LIGHT_GOLD, 0.075)
    eyeStroke("EyeTail", {
        { 0.76, 0.0 }, { 0.95, 0.10 }, { 1.04, 0.20 },
    }, LIGHT_GOLD, 0.065)
    eyeStroke("EyeTear", {
        { 0.33, -0.16 }, { 0.38, -0.40 }, { 0.42, -0.66 }, { 0.50, -0.72 },
    }, LIGHT_GOLD, 0.070)
    eyeStroke("EyeCurl", {
        { -0.29, -0.17 }, { -0.29, -0.43 }, { -0.38, -0.57 },
        { -0.62, -0.64 }, { -0.74, -0.57 }, { -0.73, -0.45 },
        { -0.61, -0.40 }, { -0.52, -0.47 },
    }, LIGHT_GOLD, 0.062)
    local faceTilt = math.atan(half / height)
    part("EyeIris", vec(0.31, 0.37, 0.08),
        CFrame.new(eyePoint(0, 0, 0.095)) * CFrame.Angles(-faceTilt, 0, 0),
        EDGE_GOLD, Enum.PartType.Ball)
    part("EyePupil", vec(0.13, 0.30, 0.08),
        CFrame.new(eyePoint(0, 0, 0.137)) * CFrame.Angles(-faceTilt, 0, 0),
        EYE_DARK, Enum.PartType.Ball)
    local loopY = topY + 0.83
    local radiusX = 0.42
    local radiusY = 0.70
    local ringSegments = 24
    part("LoopMount", vec(0.44, 0.20, 0.32),
        CFrame.new(vec(0, topY + 0.16, 0)), EDGE_GOLD)
    for index = 0, ringSegments - 1 do
        local a = index / ringSegments * math.pi * 2
        local b = (index + 1) / ringSegments * math.pi * 2
        line("PendantLoop_" .. string.format("%02d", index + 1),
            vec(math.cos(a) * radiusX, loopY + math.sin(a) * radiusY, 0),
            vec(math.cos(b) * radiusX, loopY + math.sin(b) * radiusY, 0),
            0.10, 0.14, LIGHT_GOLD)
    end
    for _, object in ipairs(model:GetChildren()) do
        if object:IsA("BasePart") and object ~= root then
            object.CFrame = object.CFrame + vec(0, -bottomY + 0.09, 0)
        end
    end
    model:SetAttribute("PartCount", partCount)
    model:PivotTo(options.cframe or CFrame.new())
    model.Parent = parent
    return model
end
return MillenniumPuzzle
