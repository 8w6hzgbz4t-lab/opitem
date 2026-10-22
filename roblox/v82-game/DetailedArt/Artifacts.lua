-- Detailed, static artifact collectibles. All geometry is created locally.
-- Catalog IDs, prices, income, rarity and powers are deliberately untouched.
local M = {}
local V, CF = Vector3.new, CFrame.new
local RGB = Color3.fromRGB
local METAL, GLASS, NEON = Enum.Material.Metal, Enum.Material.Glass, Enum.Material.Neon
local GOLD, GOLD_LIGHT, GOLD_DARK = RGB(208,149,42), RGB(251,212,115), RGB(120,74,23)
local BLACK, IVORY = RGB(24,23,27), RGB(241,235,205)
local TAU = math.pi * 2

local function band(b, name, frame, radius, thickness, color, segments, material)
    b:ring(name, frame, radius, thickness, color, segments or 16, material or METAL)
end

local function gemstone(b, name, position, color, radius)
    radius = radius or .18
    b:ball(name .. "Stone", V(radius*1.8,radius*1.8,.19), CF(position), color, GLASS)
    band(b, name .. "Bezel", CF(position+V(0,0,.045)), radius, .045, GOLD_LIGHT, 8)
    for i=0,3 do
        local a=i*math.pi*.5
        local frame=CF(position+V(math.cos(a)*radius*.52,math.sin(a)*radius*.52,-.105))
            * CFrame.Angles(0,0,a)
        b:wedge(name .. "Facet" .. i,V(.07,radius*.72,.065),frame,color,METAL)
    end
end

local function gauntlet(b)
    -- The wrist, palm and all four fingers have separate overlapping armor plates.
    for i=0,2 do
        local y=.25+i*.29
        b:box("WristArmor"..i,V(1.80-i*.08,.28,1.02),CF(0,y,0),i%2==0 and GOLD or GOLD_DARK,METAL)
        b:box("WristFrontLip"..i,V(1.88-i*.08,.07,.08),CF(0,y+.12,-.56),GOLD_LIGHT,METAL)
        b:box("WristBackLip"..i,V(1.88-i*.08,.07,.08),CF(0,y+.12,.56),GOLD_LIGHT,METAL)
        for _,s in ipairs({-1,1}) do
            b:ball("WristRivet"..i.."_"..s,V(.10,.10,.06),CF(s*.67,y,-.60),GOLD_LIGHT,METAL)
        end
    end
    b:box("PalmCore",V(1.82,1.48,.90),CF(0,1.69,0),GOLD_DARK,METAL)
    b:box("PalmCenterPlate",V(1.28,1.22,.13),CF(0,1.68,-.50),GOLD,METAL)
    for _,s in ipairs({-1,1}) do
        b:wedge("PalmSidePlate"..s,V(.16,1.18,.44),CF(s*.77,1.68,-.32)*CFrame.Angles(0,s*math.pi*.5,0),GOLD_LIGHT,METAL)
        b:line("PalmEtch"..s,V(s*.56,1.12,-.585),V(s*.65,2.16,-.585),.03,.022,GOLD_DARK,METAL)
        b:line("PalmBrace"..s,V(s*.82,1.05,-.52),V(s*.60,2.28,-.52),.075,.055,GOLD_LIGHT,METAL)
    end
    b:box("KnuckleBar",V(1.96,.25,.91),CF(0,2.46,0),GOLD,METAL)
    local fingerHeights={1.35,1.75,1.62,1.22}
    local fingerColors={RGB(171,76,223),RGB(74,157,247),RGB(221,53,48),RGB(250,163,37)}
    for i=1,4 do
        local x=(i-2.5)*.48
        local length=fingerHeights[i]
        for joint=0,2 do
            local y=2.60+(joint+.5)*length/3
            b:box("Finger"..i.."Joint"..joint,V(.40,length/3-.025,.67),CF(x,y,0),GOLD_DARK,METAL)
            b:box("Finger"..i.."FrontPlate"..joint,V(.43,length/3-.05,.15),CF(x,y,-.38),GOLD,METAL)
            b:box("Finger"..i.."JointRim"..joint,V(.44,.055,.73),CF(x,y-length/6+.035,0),GOLD_LIGHT,METAL)
        end
        b:ball("FingerCap"..i,V(.41,.20,.70),CF(x,2.62+length,0),GOLD_LIGHT,METAL)
        gemstone(b,"KnuckleGem"..i,V(x,2.52,-.535),fingerColors[i],.145)
    end
    local thumbFrame=CF(1.15,1.72,0)*CFrame.Angles(0,0,-.57)
    for i=0,2 do
        local frame=thumbFrame*CF(0,i*.38,0)
        b:box("ThumbJoint"..i,V(.50,.39,.68),frame,GOLD,METAL)
        b:box("ThumbRim"..i,V(.54,.06,.73),frame*CF(0,-.14,0),GOLD_LIGHT,METAL)
    end
    gemstone(b,"ThumbTimeGem",V(1.33,1.94,-.45),RGB(71,205,110),.16)
    gemstone(b,"PalmMindGem",V(0,1.75,-.68),RGB(255,219,67),.36)
    for _,s in ipairs({-1,1}) do
        b:line("PalmChevron"..s,V(s*.35,1.14,-.60),V(0,.96,-.60),.065,.04,GOLD_LIGHT,METAL)
        b:line("MindGemRay"..s,V(s*.42,1.70,-.63),V(s*.65,1.57,-.63),.045,.03,GOLD_LIGHT,METAL)
    end
end

local function oneRing(b)
    -- Three circular courses create a genuine opening and a broad engraved band.
    local center=V(0,1.85,0)
    for i=-1,1 do
        band(b,"RingCourse"..i,CF(center+V(0,0,i*.18)),1.55,.27,i==0 and GOLD or GOLD_LIGHT,24)
    end
    band(b,"InnerBevel",CF(center+V(0,0,-.26)),1.405,.065,GOLD_DARK,24)
    local runeStrokes={
        {{-.09,-.07},{.00,.10}},{{.00,.10},{.09,-.04}},{{-.075,.01},{.07,.04}},
    }
    for i=0,23 do
        local a=i*TAU/24
        local frame=CF(center+V(math.sin(a)*1.55,math.cos(a)*1.55,-.34))*CFrame.Angles(0,0,-a)
        for j,stroke in ipairs(runeStrokes) do
            b:line("EngravedRune"..i.."Stroke"..j,
                frame*V(stroke[1][1],stroke[1][2],0),
                frame*V(stroke[2][1],stroke[2][2],0),.027,.012,GOLD_DARK,METAL)
        end
        if i%3==0 then
            b:ball("RuneDot"..i,V(.032,.032,.022),frame*CF(.12,-.03,0),GOLD_DARK,METAL)
        end
    end
end

local function emerald(b)
    local n=8
    local top, shoulder, girdle={}, {}, {}
    local colors={RGB(63,225,139),RGB(18,139,96),RGB(98,245,158),RGB(12,169,105)}
    for i=1,n do
        local a=(i-1)*TAU/n+math.pi/8
        top[i]=V(math.cos(a)*.76,3.78,math.sin(a)*.57)
        shoulder[i]=V(math.cos(a)*1.50,2.93,math.sin(a)*1.02)
        girdle[i]=V(math.cos(a)*1.50,2.57,math.sin(a)*1.02)
    end
    for i=1,n do
        local j=i%n+1
        local col=colors[(i-1)%#colors+1]
        b:triangle("Table"..i,V(0,3.78,0),top[i],top[j],RGB(88,237,158),.045,GLASS)
        b:triangle("CrownA"..i,top[i],shoulder[i],shoulder[j],col,.045,GLASS)
        b:triangle("CrownB"..i,top[i],shoulder[j],top[j],colors[i%#colors+1],.045,GLASS)
        b:triangle("GirdleA"..i,shoulder[i],girdle[i],girdle[j],RGB(15,111,74),.04,METAL)
        b:triangle("GirdleB"..i,shoulder[i],girdle[j],shoulder[j],RGB(50,210,126),.04,METAL)
        b:triangle("Pavilion"..i,girdle[i],V(0,.32,0),girdle[j],col,.045,GLASS)
        b:line("FacetBoundary"..i,top[i],shoulder[i],.018,.018,RGB(152,255,204),METAL)
        b:line("LowerFacetBoundary"..i,girdle[i],V(0,.32,0),.018,.018,RGB(17,128,84),METAL)
    end
    local core=b:ball("EmeraldLightCore",V(.9,1.7,.60),CF(0,2.65,0),RGB(62,234,128),NEON)
    core.Transparency=.18
end

local function spike(b,name,base,direction,length,radius)
    local up=direction.Unit
    local reference=math.abs(up.Y)>.9 and V(1,0,0) or V(0,1,0)
    local right=up:Cross(reference).Unit
    local front=up:Cross(right).Unit
    local corners={base+right*radius,base+front*radius,base-right*radius,base-front*radius}
    for i=1,4 do
        b:triangle(name.."Face"..i,corners[i],base+up*length,corners[i%4+1],
            i%2==0 and IVORY or RGB(255,253,227),.045,METAL)
    end
end

local function shell(b)
    local BLUE, DARK_BLUE=RGB(42,112,224),RGB(18,59,129)
    b:ball("BlueShellDome",V(2.85,2.50,2.55),CF(0,1.85,0),BLUE,METAL)
    b:ball("ShellUnderside",V(2.83,.63,2.52),CF(0,.92,0),IVORY,METAL)
    band(b,"ShellWhiteRim",CF(0,1.18,0)*CFrame.Angles(math.pi*.5,0,0),1.37,.16,IVORY,20)
    band(b,"ShellTopPanel",CF(0,3.03,0)*CFrame.Angles(math.pi*.5,0,0),.47,.055,DARK_BLUE,6)
    for i=0,5 do
        local a=i*TAU/6
        local c=V(math.cos(a)*1.03,2.14,math.sin(a)*.95)
        local normal=V(math.cos(a),.6,math.sin(a)).Unit
        local right=normal:Cross(V(0,1,0)).Unit
        local facing=CFrame.fromMatrix(c,right,right:Cross(normal).Unit,-normal)
        band(b,"HexShellPanel"..i,facing,.52,.052,DARK_BLUE,6)
        spike(b,"Spine"..i,V(math.cos(a)*.86,2.62,math.sin(a)*.80),
            V(math.cos(a)*.4,.95,math.sin(a)*.4),.66,.24)
    end
    spike(b,"CrownSpine",V(0,3.10,0),V(0,1,0),.73,.27)
    for _,s in ipairs({-1,1}) do
        local base=V(s*1.04,1.87,.24)
        b:ball("WingRoot"..s,V(.50,.78,.35),CF(base),IVORY,METAL)
        b:triangle("WingWeb"..s,base,V(s*1.76,3.15,.32),V(s*2.37,2.39,.27),IVORY,.11,METAL)
        for i=0,3 do
            local low=base+V(s*(.13+i*.18),.10+i*.16,0)
            local tip=V(s*(2.55-i*.17),2.73+i*.22,.23)
            local high=low+V(0,.27,0)
            b:triangle("WingFeather"..s.."_"..i,low,tip,high,RGB(250-i*5,249-i*5,231-i*3),.11,METAL)
            b:line("WingFeatherQuill"..s.."_"..i,low+V(0,.08,-.08),tip+V(0,0,-.08),.032,.025,RGB(198,202,206),METAL)
        end
    end
end

local function zenobutton(b)
    local BLUE, LIGHT=RGB(81,160,221),RGB(174,226,249)
    b:box("ControllerBody",V(2.05,1.93,.66),CF(0,2.01,0),BLUE,METAL)
    b:ball("ControllerRoundedTop",V(2.05,1.35,.66),CF(0,2.98,0),BLUE,METAL)
    b:ball("ControllerRoundedBottom",V(2.05,1.25,.66),CF(0,1.07,0),BLUE,METAL)
    b:box("InsetFace",V(1.73,1.86,.09),CF(0,2.0,-.36),LIGHT,METAL)
    b:ball("InsetFaceTop",V(1.73,1.11,.09),CF(0,2.90,-.36),LIGHT,METAL)
    b:ball("InsetFaceBottom",V(1.73,.99,.09),CF(0,1.15,-.36),LIGHT,METAL)
    b:box("RearPlate",V(1.56,1.7,.08),CF(0,2.0,.36),RGB(39,103,162),METAL)
    b:line("Antenna",V(0,3.60,0),V(0,4.45,0),.09,.09,RGB(214,228,232),METAL)
    b:ball("AntennaTip",.22,CF(0,4.48,0),GOLD_LIGHT,METAL)
    b:ball("ButtonSocket",V(1.1,1.1,.17),CF(0,1.73,-.44),BLACK,METAL)
    band(b,"ButtonGuard",CF(0,1.73,-.53),.53,.082,RGB(220,228,230),12)
    b:ball("LargeRedButton",V(.88,.88,.34),CF(0,1.73,-.62),RGB(224,54,65),METAL)
    b:ball("ButtonHighlight",V(.18,.11,.04),CF(-.20,1.93,-.795),RGB(255,153,157),METAL)
    b:ball("UpperIndicator",V(.38,.38,.09),CF(0,2.88,-.44),RGB(54,188,118),NEON)
    band(b,"UpperIndicatorBezel",CF(0,2.88,-.44),.25,.045,RGB(219,229,230),10)
    for _,s in ipairs({-1,1}) do
        for i=0,3 do
            b:box("GripGroove"..s.."_"..i,V(.055,.10,.63),CF(s*1.04,1.56+i*.25,0),RGB(33,102,152),METAL)
        end
        for _,y in ipairs({1.14,2.47}) do
            b:ball("FaceScrew"..s.."_"..y,V(.09,.09,.045),CF(s*.73,y,-.42),RGB(101,135,151),METAL)
        end
        b:line("ControllerTrim"..s,V(s*.90,1.33,-.40),V(s*.90,2.64,-.40),.035,.025,RGB(231,242,244),METAL)
    end
    for i=0,2 do
        b:box("BottomStatusTick"..i,V(.18,.07,.025),CF((i-1)*.28,.98,-.43),RGB(80,147,179),METAL)
    end
end

local function cardEmboss(b,frame,kind)
    local function box(name,size,cf,color)
        b:box(name,size,frame*cf,color or GOLD,METAL)
    end
    local function line(name,a,c,width,color)
        b:line(name,frame*a,frame*c,width,.06,color or GOLD_LIGHT,METAL)
    end
    if kind=="head" then
        box("ExodiaFace",V(.43,.49,.15),CF(0,.12,-.18),GOLD)
        box("ExodiaHeadgear",V(.58,.20,.16),CF(0,.44,-.18),GOLD_LIGHT)
        for _,s in ipairs({-1,1}) do
            line("ExodiaHorn"..s,V(s*.23,.46,-.19),V(s*.37,.72,-.19),.095)
            box("ExodiaCheek"..s,V(.11,.32,.19),CF(s*.20,.0,-.21),GOLD_DARK)
            b:ball("ExodiaEye"..s,V(.085,.046,.045),frame*CF(s*.105,.15,-.29),RGB(197,34,42),NEON)
            line("ExodiaBrow"..s,V(s*.02,.225,-.30),V(s*.16,.26,-.30),.035)
            line("ExodiaShoulder"..s,V(s*.13,-.23,-.17),V(s*.42,-.37,-.17),.14)
        end
        b:wedge("ExodiaNose",V(.08,.16,.10),frame*CF(0,.03,-.30),GOLD_LIGHT,METAL)
        line("ExodiaMouth",V(-.08,-.125,-.29),V(.08,-.125,-.29),.025,GOLD_DARK)
        box("ExodiaTorso",V(.37,.34,.12),CF(0,-.35,-.16),GOLD)
    elseif kind=="leftArm" or kind=="rightArm" then
        local s=kind=="leftArm" and -1 or 1
        b:ball("ExodiaArmShoulder"..s,V(.36,.36,.15),frame*CF(-s*.09,.42,-.17),GOLD_LIGHT,METAL)
        line("ExodiaUpperArm"..s,V(-s*.10,.28,-.18),V(s*.16,-.02,-.18),.22,GOLD)
        b:ball("ExodiaElbow"..s,V(.26,.26,.14),frame*CF(s*.16,-.02,-.18),GOLD_DARK,METAL)
        line("ExodiaForearm"..s,V(s*.16,-.04,-.18),V(s*.05,-.43,-.18),.25,GOLD_LIGHT)
        box("ExodiaFist"..s,V(.30,.24,.15),CF(s*.045,-.48,-.19),GOLD)
        for i=0,2 do
            box("ExodiaFinger"..s.."_"..i,V(.075,.10,.04),CF(s*.045+(i-1)*.083,-.47,-.29),GOLD_LIGHT)
        end
    else
        local s=kind=="leftLeg" and -1 or 1
        line("ExodiaThigh"..s,V(-s*.11,.49,-.17),V(s*.09,.02,-.17),.25,GOLD)
        b:ball("ExodiaKnee"..s,V(.32,.30,.17),frame*CF(s*.09,.00,-.19),GOLD_LIGHT,METAL)
        line("ExodiaShin"..s,V(s*.09,-.12,-.18),V(s*.04,-.48,-.18),.27,GOLD)
        box("ExodiaAnkle"..s,V(.24,.13,.15),CF(s*.04,-.46,-.19),GOLD_DARK)
        b:wedge("ExodiaFoot"..s,V(.38,.25,.18),frame*CF(s*.06,-.59,-.20)*CFrame.Angles(0,0,math.pi*.5),GOLD_LIGHT,METAL)
        for i=0,2 do
            box("ExodiaToe"..s.."_"..i,V(.09,.075,.04),CF(s*.06+(i-1)*.10,-.63,-.32),GOLD)
        end
    end
end

local function cards(b)
    local kinds={"leftLeg","leftArm","head","rightArm","rightLeg"}
    for i=1,5 do
        local offset=i-3
        local frame=CF(offset*.88,1.54-math.abs(offset)*.09,math.abs(offset)*.16)
            * CFrame.Angles(0,0,-offset*.09)
        b:box("Card"..i.."Body",V(1.23,2.25,.10),frame,RGB(134,78,36),METAL)
        b:box("Card"..i.."ArtPanel",V(1.02,1.50,.045),frame*CF(0,.08,-.078),RGB(62,40,28),METAL)
        b:box("Card"..i.."NamePlate",V(1.02,.19,.045),frame*CF(0,.91,-.078),RGB(230,202,149),METAL)
        b:box("Card"..i.."RulesPanel",V(1.02,.24,.045),frame*CF(0,-.86,-.078),RGB(215,194,154),METAL)
        for _,s in ipairs({-1,1}) do
            b:box("Card"..i.."VerticalBorder"..s,V(.045,2.20,.045),frame*CF(s*.585,0,-.075),GOLD_LIGHT,METAL)
            b:box("Card"..i.."HorizontalBorder"..s,V(1.19,.045,.045),frame*CF(0,s*1.08,-.075),GOLD_LIGHT,METAL)
        end
        for star=0,2 do
            b:ball("Card"..i.."LevelPip"..star,V(.075,.075,.035),frame*CF(.22+star*.13,.73,-.115),RGB(244,175,56),METAL)
        end
        for row=0,1 do
            b:box("Card"..i.."RulesLine"..row,V(.79-row*.12,.017,.018),frame*CF(-.02,-.82-row*.065,-.115),RGB(85,63,37),METAL)
        end
        cardEmboss(b,frame,kinds[i])
    end
end

local function materia(b)
    local green=RGB(50,226,120)
    local outer=b:ball("MateriaGlassOrb",2.30,CF(0,2.21,0),RGB(85,216,164),GLASS)
    outer.Transparency=.25
    local core=b:ball("MateriaLuminousCore",1.59,CF(0,2.21,0),green,NEON)
    core.Transparency=.12
    b:cylinder("MateriaBase",V(.20,1.48,1.48),CF(0,.19,0)*CFrame.Angles(0,0,math.pi*.5),GOLD_DARK,METAL)
    b:cylinder("MateriaFootRim",V(.085,1.61,1.61),CF(0,.29,0)*CFrame.Angles(0,0,math.pi*.5),GOLD_LIGHT,METAL)
    b:cylinder("MateriaStem",V(.42,.39,.39),CF(0,.54,0)*CFrame.Angles(0,0,math.pi*.5),GOLD,METAL)
    band(b,"MateriaSocket",CF(0,1.32,0)*CFrame.Angles(math.pi*.5,0,0),.77,.10,GOLD,12)
    for i=0,3 do
        local a=i*TAU/4
        b:line("SocketStrut"..i,V(math.cos(a)*.17,.72,math.sin(a)*.17),V(math.cos(a)*.77,1.33,math.sin(a)*.77),.085,.085,GOLD_LIGHT,METAL)
        b:ball("SocketClaw"..i,.13,CF(math.cos(a)*.77,1.33,math.sin(a)*.77),GOLD_LIGHT,METAL)
    end
    band(b,"MateriaOrbitA",CF(0,2.21,0)*CFrame.Angles(.31,.48,0),1.17,.025,RGB(169,255,214),16,GLASS)
    band(b,"MateriaOrbitB",CF(0,2.21,0)*CFrame.Angles(1.11,-.21,.41),1.17,.025,RGB(104,238,205),16,GLASS)
    for i=0,7 do
        local a=i*TAU/8
        local frame=CF(math.cos(a)*.70,2.21+math.sin(a)*.70,-.93)
        b:box("MateriaRune"..i,V(.065,.10,.035),frame*CFrame.Angles(0,0,-a),RGB(198,255,234),NEON)
    end
end

local function commandblock(b)
    local orange=RGB(183,110,54)
    b:box("CommandBlockCore",V(3.1,3.1,3.1),CF(0,1.65,0),orange,Enum.Material.SmoothPlastic)
    local rotations={
        CFrame.Angles(0,0,0),CFrame.Angles(0,math.pi,0),
        CFrame.Angles(0,-math.pi*.5,0),CFrame.Angles(0,math.pi*.5,0),
        CFrame.Angles(math.pi*.5,0,0),CFrame.Angles(-math.pi*.5,0,0),
    }
    for face,rotation in ipairs(rotations) do
        local f=CF(0,1.65,0)*rotation*CF(0,0,-1.57)
        b:box("CommandFaceInset"..face,V(1.13,1.13,.045),f,RGB(69,86,83),METAL)
        for row=-1,1 do
            for col=-1,1 do
                local colors={RGB(213,224,203),RGB(157,192,166),RGB(119,155,139)}
                local color=colors[(row+col+6)%3+1]
                b:box("CommandCell"..face.."_"..row.."_"..col,V(.28,.28,.045),f*CF(col*.35,row*.35,-.041),color,Enum.Material.SmoothPlastic)
            end
        end
        for _,s in ipairs({-1,1}) do
            b:box("CommandRimVertical"..face.."_"..s,V(.07,3.02,.045),f*CF(s*1.46,0,0),RGB(101,61,40),METAL)
            b:box("CommandRimHorizontal"..face.."_"..s,V(3.02,.07,.045),f*CF(0,s*1.46,0),RGB(101,61,40),METAL)
            for _,t in ipairs({-1,1}) do
                b:box("CommandPaintCorner"..face.."_"..s.."_"..t,V(.51,.52,.038),f*CF(s*1.02,t*1.02,-.020),RGB(218,149,80),Enum.Material.SmoothPlastic)
                b:ball("CommandCornerBolt"..face.."_"..s.."_"..t,V(.13,.13,.045),f*CF(s*1.28,t*1.28,-.043),RGB(122,79,48),METAL)
            end
        end
    end
end

local function endcrystal(b)
    local BEDROCK, PINK=RGB(45,42,50),RGB(226,73,175)
    b:box("BedrockPedestal",V(2.35,.65,2.35),CF(0,.40,0),BEDROCK,Enum.Material.Slate)
    for row=-1,1 do
        for col=-1,1 do
            b:box("BedrockTopTile"..row.."_"..col,V(.70,.04,.70),CF(col*.75,.747,row*.75),
                (row+col)%2==0 and RGB(83,80,89) or RGB(60,60,70),Enum.Material.Slate)
        end
    end
    for side=0,3 do
        local frame=CF(0,.43,0)*CFrame.Angles(0,side*math.pi*.5,0)*CF(0,0,-1.18)
        for i=0,2 do
            b:box("BedrockSideTile"..side.."_"..i,V(.54,.31,.035),frame*CF((i-1)*.74,(i%2)*.08-.04,0),RGB(65+i*6,62+i*5,74+i*4),Enum.Material.Slate)
        end
    end
    local f=CF(0,2.76,0)*CFrame.Angles(0,math.pi*.25,0)
    local r=1.20
    for _,x in ipairs({-1,1}) do
        for _,y in ipairs({-1,1}) do
            b:line("CrystalEdgeZ"..x.."_"..y,f*V(x*r,y*r,-r),f*V(x*r,y*r,r),.065,.065,RGB(212,204,229),GLASS)
        end
    end
    for _,x in ipairs({-1,1}) do
        for _,z in ipairs({-1,1}) do
            b:line("CrystalEdgeY"..x.."_"..z,f*V(x*r,-r,z*r),f*V(x*r,r,z*r),.065,.065,RGB(219,209,235),GLASS)
        end
    end
    for _,y in ipairs({-1,1}) do
        for _,z in ipairs({-1,1}) do
            b:line("CrystalEdgeX"..y.."_"..z,f*V(-r,y*r,z*r),f*V(r,y*r,z*r),.065,.065,RGB(222,210,237),GLASS)
        end
    end
    for axis=1,3 do
        for _,s in ipairs({-1,1}) do
            local size=axis==1 and V(.035,r*2,r*2) or axis==2 and V(r*2,.035,r*2) or V(r*2,r*2,.035)
            local offset=axis==1 and V(s*r,0,0) or axis==2 and V(0,s*r,0) or V(0,0,s*r)
            local pane=b:box("CrystalGlassPane"..axis.."_"..s,size,f*CF(offset),RGB(194,171,215),GLASS)
            pane.Transparency=.80
        end
    end
    for i=0,7 do
        local a=i*TAU/8
        local c=V(math.cos(a)*.71,2.73,math.sin(a)*.71)
        local d=V(math.cos((i+1)*TAU/8)*.71,2.73,math.sin((i+1)*TAU/8)*.71)
        b:triangle("EndCrystalUpper"..i,c,V(0,3.78,0),d,i%2==0 and PINK or RGB(255,150,219),.06,NEON)
        b:triangle("EndCrystalLower"..i,c,d,V(0,1.75,0),i%2==0 and RGB(143,44,148) or PINK,.06,METAL)
    end
    band(b,"FloatingCrystalHalo",CF(0,1.13,0)*CFrame.Angles(math.pi*.5,0,0),.86,.038,RGB(191,81,223),12,NEON)
    for i=0,3 do
        local a=i*TAU/4
        b:ball("PedestalAnchor"..i,.11,CF(math.cos(a)*.91,.80,math.sin(a)*.91),RGB(189,136,220),METAL)
    end
end

local function arkenstone(b)
    local n=8
    local profiles={{.33,.12},{1.03,.77},{2.35,1.23},{3.30,.72},{3.66,.13}}
    local rings={}
    for level,profile in ipairs(profiles) do
        rings[level]={}
        for i=1,n do
            local a=(i-1)*TAU/n
            rings[level][i]=V(math.cos(a)*profile[2],profile[1],math.sin(a)*profile[2]*.79)
        end
    end
    local colors={RGB(229,249,244),RGB(206,225,248),RGB(249,238,254),RGB(194,238,233),RGB(255,251,237)}
    for level=1,#rings-1 do
        for i=1,n do
            local j=i%n+1
            b:triangle("ArkenstoneFacetA"..level.."_"..i,rings[level][i],rings[level+1][i],rings[level+1][j],
                colors[(level+i)%#colors+1],.055,GLASS)
            b:triangle("ArkenstoneFacetB"..level.."_"..i,rings[level][i],rings[level+1][j],rings[level][j],
                colors[(level+i+2)%#colors+1],.055,METAL)
        end
    end
    for i=1,n do
        local j=i%n+1
        b:triangle("ArkenstoneTable"..i,rings[#rings][i],V(0,3.66,0),rings[#rings][j],RGB(247,255,252),.035,GLASS)
    end
    local core=b:ball("ArkenstoneHeartLight",V(.76,1.70,.63),CF(0,2.17,0),RGB(196,251,248),NEON)
    core.Transparency=.16
    b:line("ArkenstoneGlintHorizontal",V(-.55,2.74,-.78),V(-.23,2.74,-.78),.022,.020,RGB(255,255,255),NEON)
    b:line("ArkenstoneGlintVertical",V(-.39,2.52,-.78),V(-.39,2.97,-.78),.022,.020,RGB(255,255,255),NEON)
end

local glyphs={
    D={{{0,0},{0,1}},{{0,1},{.65,1}},{{.65,1},{1,.7}},{{1,.7},{1,.3}},{{1,.3},{.65,0}},{{.65,0},{0,0}}},
    E={{{0,0},{0,1}},{{0,1},{1,1}},{{0,.5},{.8,.5}},{{0,0},{1,0}}},
    A={{{0,0},{.5,1}},{{.5,1},{1,0}},{{.23,.43},{.77,.43}}},
    T={{{0,1},{1,1}},{{.5,1},{.5,0}}},
    H={{{0,0},{0,1}},{{1,0},{1,1}},{{0,.5},{1,.5}}},
    N={{{0,0},{0,1}},{{0,1},{1,0}},{{1,0},{1,1}}},
    O={{{.25,0},{.75,0}},{{.75,0},{1,.25}},{{1,.25},{1,.75}},{{1,.75},{.75,1}},{{.75,1},{.25,1}},{{.25,1},{0,.75}},{{0,.75},{0,.25}},{{0,.25},{.25,0}}},
}

local function deathnote(b)
    local frame=CF(0,2.03,0)*CFrame.Angles(0,-.10,-.075)
    b:box("NotebookPages",V(2.64,3.64,.39),frame,RGB(210,202,183),Enum.Material.SmoothPlastic)
    b:box("NotebookFrontCover",V(2.89,3.90,.10),frame*CF(0,0,-.25),BLACK,METAL)
    b:box("NotebookBackCover",V(2.89,3.90,.10),frame*CF(0,0,.25),RGB(16,17,20),METAL)
    b:box("NotebookSpine",V(.20,3.90,.56),frame*CF(-1.36,0,0),RGB(18,18,22),METAL)
    for i=0,10 do
        local z=-.18+i*.036
        b:line("PageEdgeRight"..i,frame*V(1.327,-1.78,z),frame*V(1.327,1.78,z),.014,.014,RGB(153,145,130),Enum.Material.SmoothPlastic)
        b:line("PageEdgeBottom"..i,frame*V(-1.20,-1.826,z),frame*V(1.30,-1.826,z),.014,.014,RGB(153,145,130),Enum.Material.SmoothPlastic)
    end
    local function title(word,baseline,width,height)
        local spacing=width+.13
        local x0=-(#word*spacing-.13)*.5
        for index=1,#word do
            local letter=word:sub(index,index)
            for stroke,points in ipairs(glyphs[letter]) do
                local a,c=points[1],points[2]
                b:line("CoverTitle"..word.."_"..index.."_"..stroke,
                    frame*V(x0+(index-1)*spacing+a[1]*width,baseline+a[2]*height,-.312),
                    frame*V(x0+(index-1)*spacing+c[1]*width,baseline+c[2]*height,-.312),
                    .034,.018,RGB(222,221,214),METAL)
            end
        end
    end
    title("DEATH",.60,.32,.53)
    title("NOTE",-.16,.34,.54)
    for _,s in ipairs({-1,1}) do
        b:line("CoverInsetSide"..s,frame*V(s*1.19,-1.70,-.305),frame*V(s*1.19,1.69,-.305),.022,.016,RGB(45,45,52),METAL)
        b:line("CoverInsetEnd"..s,frame*V(-1.19,s*1.69,-.305),frame*V(1.19,s*1.69,-.305),.022,.016,RGB(45,45,52),METAL)
    end
    b:box("NotebookBookmark",V(.10,.68,.025),frame*CF(.96,-1.88,.02),RGB(105,26,31),Enum.Material.Fabric)
    b:line("CoverScuffA",frame*V(-.90,-1.17,-.31),frame*V(-.72,-1.25,-.31),.019,.012,RGB(82,79,80),METAL)
    b:line("CoverScuffB",frame*V(.82,1.48,-.31),frame*V(1.05,1.38,-.31),.019,.012,RGB(82,79,80),METAL)
end

local function triforce(b)
    local triangles={
        {V(-1.64,.34,0),V(-.10,.34,0),V(-.87,1.67,0)},
        {V(.10,.34,0),V(1.64,.34,0),V(.87,1.67,0)},
        {V(-.77,1.80,0),V(.77,1.80,0),V(0,3.13,0)},
    }
    for index,points in ipairs(triangles) do
        local center=(points[1]+points[2]+points[3])/3
        b:triangle("TriforceSolid"..index,points[1],points[2],points[3],GOLD,.28,METAL)
        for i=1,3 do
            local j=i%3+1
            local a=points[i]+V(0,0,-.16)
            local c=points[j]+V(0,0,-.16)
            b:triangle("TriforceFace"..index.."_"..i,a,center+V(0,0,-.19),c,
                i==1 and GOLD_LIGHT or i==2 and GOLD or RGB(234,180,63),.025,METAL)
            b:line("TriforceEdge"..index.."_"..i,a,c,.055,.045,GOLD_LIGHT,METAL)
            b:line("TriforceEngraving"..index.."_"..i,
                center+(points[i]-center)*.68+V(0,0,-.205),
                center+(points[j]-center)*.68+V(0,0,-.205),.023,.014,GOLD_DARK,METAL)
            local stud=center+(points[i]-center)*.80+V(0,0,-.205)
            b:ball("TriforceCornerSeal"..index.."_"..i,V(.075,.075,.045),CF(stud),GOLD_LIGHT,METAL)
        end
    end
end

local function millenniumRod(b)
    b:cylinder("RodShaft",V(2.85,.24,.24),CF(0,1.97,0)*CFrame.Angles(0,0,math.pi*.5),GOLD,METAL)
    b:cylinder("RodPommel",V(.16,.39,.39),CF(0,.60,0)*CFrame.Angles(0,0,math.pi*.5),GOLD_LIGHT,METAL)
    spike(b,"RodPoint",V(0,.51,0),V(0,-1,0),.45,.17)
    for i=0,9 do
        b:cylinder("GripBand"..i,V(.045,.28,.28),CF(0,.77+i*.095,0)*CFrame.Angles(0,0,math.pi*.5),
            i%2==0 and GOLD_DARK or GOLD_LIGHT,METAL)
    end
    b:cylinder("RodCollar",V(.18,.53,.53),CF(0,3.22,0)*CFrame.Angles(0,0,math.pi*.5),GOLD_LIGHT,METAL)
    b:ball("RodEyeHead",V(1.42,1.37,.55),CF(0,3.92,0),GOLD,METAL)
    band(b,"RodHeadBezel",CF(0,3.92,-.20),.68,.065,GOLD_LIGHT,16)
    for _,s in ipairs({-1,1}) do
        local curve={V(s*.56,3.54,0),V(s*.85,3.68,0),V(s*1.08,4.00,0),V(s*1.03,4.34,0),V(s*.91,4.60,0)}
        for i=1,#curve-1 do
            b:line("RodWingCurve"..s.."_"..i,curve[i],curve[i+1],.16-i*.019,.15,GOLD_LIGHT,METAL)
        end
        b:line("RodEyeUpper"..s,V(0,4.16,-.34),V(s*.47,3.93,-.34),.060,.05,GOLD_DARK,METAL)
        b:line("RodEyeLower"..s,V(0,3.76,-.34),V(s*.47,3.93,-.34),.060,.05,GOLD_DARK,METAL)
        b:line("RodBrow"..s,V(0,4.34,-.29),V(s*.48,4.16,-.29),.065,.05,GOLD_LIGHT,METAL)
    end
    b:ball("RodEyeIris",V(.29,.34,.11),CF(0,3.95,-.35),GOLD_LIGHT,METAL)
    b:ball("RodEyePupil",V(.12,.24,.05),CF(0,3.95,-.425),RGB(47,30,14),METAL)
    b:line("RodEyeTearA",V(.16,3.80,-.35),V(.23,3.58,-.29),.055,.05,GOLD_DARK,METAL)
    b:line("RodEyeTearB",V(.23,3.58,-.29),V(.35,3.54,-.26),.055,.05,GOLD_DARK,METAL)
    local curl={V(-.15,3.80,-.35),V(-.18,3.59,-.31),V(-.36,3.55,-.25),V(-.43,3.65,-.25)}
    for i=1,#curl-1 do
        b:line("RodEyeCurl"..i,curl[i],curl[i+1],.055,.05,GOLD_DARK,METAL)
    end
    for _,s in ipairs({-1,1}) do
        b:ball("RodHeadStud"..s,.10,CF(s*.53,3.80,-.20),GOLD_LIGHT,METAL)
    end
end

local function dwarfTreasure(b)
    local WOOD, DARK_WOOD=RGB(116,66,35),RGB(73,40,22)
    b:box("ChestBottom",V(2.68,.14,1.87),CF(0,.16,0),DARK_WOOD,Enum.Material.Wood)
    b:box("ChestInterior",V(2.42,.65,1.61),CF(0,.54,0),RGB(38,30,30),Enum.Material.Wood)
    for i=0,4 do
        local x=(i-2)*.51
        for _,s in ipairs({-1,1}) do
            b:box("ChestLongPlank"..i.."_"..s,V(.49,.97,.14),CF(x,.70,s*.87),
                i%2==0 and WOOD or RGB(133,78,41),Enum.Material.Wood)
        end
    end
    for i=0,2 do
        for _,s in ipairs({-1,1}) do
            b:box("ChestSidePlank"..i.."_"..s,V(.14,.97,.54),CF(s*1.30,.70,(i-1)*.56),WOOD,Enum.Material.Wood)
        end
    end
    for _,s in ipairs({-1,1}) do
        b:box("ChestFrontRim"..s,V(2.72,.09,.13),CF(0,1.18,s*.88),GOLD_DARK,METAL)
        b:box("ChestSideRim"..s,V(.13,.09,1.76),CF(s*1.30,1.18,0),GOLD_DARK,METAL)
        for _,t in ipairs({-1,1}) do
            b:box("ChestFrontMetalBand"..s.."_"..t,V(.15,1.05,.075),CF(s*.84,.71,t*.96),GOLD_DARK,METAL)
            for _,y in ipairs({.32,1.07}) do
                b:ball("ChestBodyRivet"..s.."_"..t.."_"..y,V(.065,.065,.04),CF(s*.84,y,t*.998),GOLD_LIGHT,METAL)
            end
        end
    end
    local lid=CF(0,1.20,.89)*CFrame.Angles(-.52,0,0)
    for i=0,4 do
        b:box("OpenLidPlank"..i,V(.52,1.75,.18),lid*CF((i-2)*.52,.87,0),i%2==0 and WOOD or RGB(135,82,48),Enum.Material.Wood)
    end
    for i=-1,1 do
        b:box("OpenLidMetalBand"..i,V(.11,1.83,.06),lid*CF(i*.87,.88,-.12),GOLD_DARK,METAL)
        for j=0,3 do
            b:ball("LidRivet"..i.."_"..j,V(.068,.068,.038),lid*CF(i*.87,.22+j*.42,-.16),GOLD_LIGHT,METAL)
        end
    end
    for _,y in ipairs({.05,1.73}) do
        b:box("LidCrossBand"..y,V(2.70,.075,.055),lid*CF(0,y,-.12),GOLD_DARK,METAL)
    end
    b:box("ChestLatch",V(.28,.33,.12),CF(0,.97,-.97),GOLD_LIGHT,METAL)
    b:ball("ChestLatchKeyhole",V(.058,.095,.02),CF(0,.98,-1.039),BLACK,METAL)
    for row=0,3 do
        for col=0,3 do
            local x=(col-1.5)*.43
            local z=(row-1.5)*.32
            local y=1.12+((row+col)%3)*.035
            b:cylinder("TreasureCoin"..row.."_"..col,V(.058,.34,.34),CF(x,y,z)*CFrame.Angles(0,0,math.pi*.5),
                (row+col)%2==0 and GOLD or GOLD_LIGHT,METAL)
            b:ball("CoinEmboss"..row.."_"..col,V(.13,.018,.13),CF(x,y+.035,z),GOLD_DARK,METAL)
        end
    end
    gemstone(b,"TreasureRuby",V(-.89,1.18,-.25),RGB(202,50,62),.15)
    gemstone(b,"TreasureSapphire",V(.83,1.22,-.12),RGB(56,103,228),.17)
    gemstone(b,"TreasureEmerald",V(.12,1.25,.41),RGB(54,194,117),.14)
end

local builders={
    gauntlet=gauntlet, oneRing=oneRing, emerald=emerald, shell=shell,
    zenobutton=zenobutton, cards=cards, materia=materia, commandblock=commandblock,
    endcrystal=endcrystal, arkenstone=arkenstone, deathnote=deathnote,
    triforce=triforce, millenniumRod=millenniumRod, dwarfTreasure=dwarfTreasure,
}

function M.build(b,key)
    local build=builders[key]
    if not build then return false end
    build(b)
    return true
end

return M

