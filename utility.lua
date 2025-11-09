return getfenv((function()
S = {
    w = workspace,
    p = game:GetService('Players'),
    ru = game:GetService('RunService'),
    re = game:GetService('ReplicatedStorage'),
    ui = game:GetService('UserInputService')
}

LocalPlayer = S.p.LocalPlayer
Character = LocalPlayer.Character
Camera = S.w.CurrentCamera

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

function setBodyMovers(part, cframe)
    local cframe = cframe or part.CFrame
    local partMass = part:GetMass()
	local BP = part:FindFirstChildOfClass('BodyPosition')
    if not BP then
        BP = Instance.new('BodyPosition', part)
    end
    BP.P = partMass * 4444.4
    BP.D = partMass * 133.3
    BP.MaxForce = Vector3.one * math.huge
    BP.Position = cframe.Position
    BP.Name = 'BP'

    local BG = part:FindFirstChildOfClass('BodyGyro')
    if not BG then
        BG = Instance.new('BodyGyro', part)
    end
    BG.P = partMass * 4444.4
    BG.D = partMass * 133.3
    BG.MaxTorque = Vector3.one * math.huge
    BG.CFrame = cframe
    BG.Name = 'BG'
end

function remBodyMovers(part)
    local BP = part:FindFirstChildOfClass('BodyPosition')
    if BP then BP:Destroy() end
    local BG = part:FindFirstChildOfClass('BodyGyro')
    if BG then BG:Destroy() end
end



function pointToLineDistance(point, linePoint, lineDirection)
    local vectorToPoint = point - linePoint
    local crossProduct = vectorToPoint:Cross(lineDirection)
    return crossProduct.Magnitude / lineDirection.Magnitude
end

function isPointInFrontOfCamera(point, cameraPosition, cameraDirection)
    local vectorToPoint = point - cameraPosition
    local dotProduct = vectorToPoint:Dot(cameraDirection)
    return dotProduct > 0
end

function closestPointToLine(points, linePoint, lineDirection)
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


function getClosestPlayer1()
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

function getClosestPlayer2()
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


oprint = print
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
  
end)())
