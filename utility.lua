

local genv = getgenv()
if genv.stop then genv.stop(); return genv.load() end
function genv.load()

local S = {
    w = workspace,
    p = game:GetService('Players'),
    ru = game:GetService('RunService'),
    re = game:GetService('ReplicatedStorage'),
    ui = game:GetService('UserInputService')
}

local LocalPlayer = S.p.LocalPlayer
local Character = LocalPlayer.Character
local Camera = S.w.CurrentCamera

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

function setBodyMovers(part, cframe, vel, force)
    local cframe = cframe or part.CFrame
    local BP = part:FindFirstChildOfClass('BodyPosition')
    if not BP then
        BP = Instance.new('BodyPosition', part)
    end
    BP.P = 100000
    BP.D = 100
    BP.MaxForce = Vector3.one * math.huge
    BP.Position = cframe.Position
    BP.Name = 'BP'

    local BG = part:FindFirstChildOfClass('BodyGyro')
    if not BG then
        BG = Instance.new('BodyGyro', part)
    end
    BG.P = 100000
    BG.D = 100
    BG.MaxTorque = Vector3.one * math.huge
    BG.CFrame = part.CFrame
    BG.Name = 'BG'

    local BV = part:FindFirstChildOfClass('BodyVelocity')
    if not BV then
        BV = Instance.new('BodyVelocity')
    end
    BV.MaxForce = Vector3.one * math.huge
    BV.P = 100000
    BV.Velocity = vel

    local BF = part:FindFirstChildOfClass('BodyForce')
    if not BF then
        BF = Instance.new('BodyVelocity')
    end
    BF.Force = force
end

local function remBodyMovers(part)
    local BP = part:FindFirstChildOfClass('BodyPosition')
    if BP then BP:Destroy() end
    local BG = part:FindFirstChildOfClass('BodyGyro')
    if BG then BG:Destroy() end
end






local function pointToLineDistance(point, linePoint, lineDirection)
    local vectorToPoint = point - linePoint
    local crossProduct = vectorToPoint:Cross(lineDirection)
    return crossProduct.Magnitude / lineDirection.Magnitude
end

local function isPointInFrontOfCamera(point, cameraPosition, cameraDirection)
    local vectorToPoint = point - cameraPosition
    local dotProduct = vectorToPoint:Dot(cameraDirection)
    return dotProduct > 0
end

local function closestPointToLine(points, linePoint, lineDirection)
    local minDistance = math.huge
    local closestPoint = nil
    
    for _, point in ipairs(points) do
        if isPointInFrontOfCamera(point, linePoint, lineDirection) then
            local distance = pointToLineDistance(point, linePoint, lineDirection)
            if distance < minDistance then
                minDistance = distance
                closestPoint = point
            end
        end
    end
    
    return closestPoint, minDistance
end


local function getClosestPlayer1()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).magnitude
            if distance < shortestDistance then
                closestPlayer = player
                shortestDistance = distance
            end
        end
    end

    return closestPlayer
end

local function getClosestPlayer2()
    local cameraPosition = Camera.CFrame.Position
    local cameraDirection = Camera.CFrame.LookVector
    local map = {}
    local positions = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
            local position = player.Character.HumanoidRootPart.Position
            map[position] = player
            table.insert(positions, position)
        end
    end
    local point, _ = closestPointToLine(positions, cameraPosition, cameraDirection)
    if not point then return end
    local player = map[point]
    return player
end


local oprint = print
function print(tbl, indent)
	local indent = indent or 0
	local formatting = string.rep("  ", indent)
	
	if type(tbl) ~= "table" then
		oprint(formatting .. tostring(tbl))
		return
	end

	oprint(formatting .. "{")
	for k, v in pairs(tbl) do
		local key = tostring(k)
		if type(v) == "table" then
			oprint(formatting .. "  " .. key .. " = ")
			print(v, indent + 2)
		else
			oprint(formatting .. "  " .. key .. " = " .. tostring(v))
		end
	end
	oprint(formatting .. "}")
end
  
end
return getfenv(genv.load())
