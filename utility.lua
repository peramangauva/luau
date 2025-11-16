
 
--[[

pretty print automatically!!
u can print tables

variables (all constantly being updated):

__loaded
custom
G - game
W - workspace
PLRS - players
RUNS - runservice
RS - replicated storage
LPLR - local player
LCHR - local character
CCM - current camera
TS - tween service
UIS - user input service
HTS - http service
MS - mouse
LGUI - player gui
BP - backpack
CG - coregui
SGUI - starter gui
SP - starter pack
tick - ticks since execution
timesinceexec - time in seconds since execution
sus - sex


Instance:

- returns nil, empty tables or self.

SetProperties(Properties)
GetAllChildrenOfClass(Classname)
GetSiblings()
Exists()
FindCharacter()
Goto(Position [, relative?])
FindFirstDescendantOfClass(Classname)
FindFirstDescendant(Name)
IsDescendantOf(Name)
GetAttachment() (get/create)
SetAttachment(Position/CFrame) (set/create)
Goto2(Position? [, CFrame?])
HolUp(T)
FindAllDescendantsOfClass(Classname)
WaitForChildOfClass(Classname, Timeout)
WaitForDescendantOfClass(Classname, Timeout)
TweenProperties(TargetProperties, T [, EasingDir?] [, EasingStyle?])
Raycast([Direction?] [, Offset?])


functions:

- returns stuff

globalizeItems(Table) 
setpartdestroyheight(Height)
setgravity(Gravity)
ispointinfrontofcamera(Point)
closestpointtoline(Points, LinePosition, LineLookVector)
getclosestplayerbydist()
getclosestplayerbylook()
raycast(Origin, Dir [, Magnitude?])


wrappers:

- returns table or function

debounce(T, Callback)
promise(Function) - .Then, .Success, .Fail, .status
callintervalp(T, Callback)
callinterval(T, Callback)

hookers:

- returns unhookers (functions)

hooknamecall(Class, Callback [, Interrupt])
hookmethod(Class, Method, Callback [, Interrupt])
hookproperty(Instance, Property, Callback)


btw
Find = table output (can be empty)
Get = can output nil

]]

if getgenv().__loaded and getgenv().__end then
    getgenv().__end()
end

getgenv().__loaded = false

if not (
    setreadonly and
    getrawmetatable and
    newcclosure and
    setrawmetatable
        ) then
    warn('UNC NOT HIGH ENOUGH. library not loaded.')
    return
end

getgenv().__loaded = true


function globalizeItems(items)
    for name, value in pairs(items) do
        getgenv()[name] = value
    end
end


local globalVars = {
    G = game,
    W = workspace,
    PLRS = game.Players,
    RUNS = game:GetService('RunService'),
    RS = game.ReplicatedStorage,
    LPLR = game.Players.LocalPlayer,
    LCHR = game.Players.LocalPlayer.Character,
    CCM = workspace.CurrentCamera,
    TS = game:GetService('TweenService'),
    UIS = game:GetService('TeleportService'),
    HTS = game:GetService('HttpService'),
    MS = game.Players.LocalPlayer:GetMouse(),
    LGUI = game.Players.LocalPlayer.PlayerGui,
    BP = game.Players.LocalPlayer.Backpack,
    CG = game.CoreGui,
    SGUI = game.StarterGui,
    SP = game.StarterPack,
    sus = 'sex'
}

globalizeItems(globalVars)

oprint = getgenv().oprint or print
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


custom = {  
    SetProperties = function(self, properties)
        for a,b in pairs(properties) do
            self[a] = b
        end
        return self
    end,
    GetAllChildrenOfClass = function(self, classname)
        local children = {}
        for _, child in ipairs(self:GetChildren()) do
            if child:IsA(classname) then
                table.insert(children, child)
            end
        end
        return children
    end,
    GetSiblings = function(self)
        local siblings = {}
        for _, child in ipairs(self.Parent:GetChildren()) do
            if child ~= self then
                table.insert(siblings, child)
            end
        end
        return siblings
    end,
    Exists = function(self)
        return self.Parent ~= nil
    end,
    FindCharacter = function(self)
        local current = self
        local function isChar()
            return current:IsA('Model') and current:FindFirstChildOfClass('Humanoid')
        end
        while current do
            if isChar() then
                return current
            end
            current = current.Parent
        end
    end,
    Goto = function(self, pos, relative)
        local relative = relative or false
        local offsets = {}
        for _, connected in ipairs(self:GetConnectedParts()) do
            offsets[connected] = connected.Position - self.Position
        end
        local newPos = relative and (self.Position + pos) or pos
        for part, offset in pairs(offsets) do
            part.Position = newPos + offset
        end
        self.Position = newPos
        return self
    end,
    FindFirstDescendantOfClass = function(self, classname)
        for _, desc in ipairs(self:GetDescendants()) do
            if desc:IsA(classname) then
                return desc
            end
        end
    end,
    FindFirstDescendant = function(self, name)
        for _, desc in ipairs(self:GetDescendants()) do
            if desc.Name == name then
                return desc
            end
        end
    end,
    IsDescendantOf = function(self, name)
        local current = self.Parent
        while current do
            if current.Name == name then
                return true
            end
            current = current.Parent
        end
    end,
    IsDescendantOfClass = function(self, classname)
        local current = self.Parent
        while current do
            if current:IsA(classname) then
                return true
            end
            current = current.Parent
        end
    end,
    GetAttachment = function(self)
        local attachment = self:FindFirstChildOfClass('Attachment') or Instance.new('Attachment')
        attachment.Parent = self
        return attachment
    end,
    SetAttachment = function(self, offset)
        local attachment = self:GetAttachment() 
        local cf = offset
        if typeof(offset) == 'Vector3' then
            cf = CFrame.new(offset)
        end
        attachment.CFrame = cf
        return attachment
    end,
    Goto2 = function(self, position, look)
        local AP = self:FindFirstChildOfClass('AlignPosition') or Instance.new('AlignPosition')
        local OP = self:FindFirstChildOfClass('AlignOrientation') or Instance.new('AlignOrientation')
        local attachment = self:GetAttachment()
        AP.Attachment0 = attachment
        OP.Attachment0 = attachment
        AP.RigidityEnabled = true
        OP.RigidityEnabled = true 
        AP.Position = position or AP.Position
        if typeof(look) == 'CFrame' then
            OP.CFrame = look
        elseif typeof(look) == 'Vector3' then
            OP.LookAtPosition = look
        end
        return self
    end,
    HolUp = function(self, t)
         task.wait(t)
         return self
    end,
    FindAllDescendantsOfClass = function(self, classname)
        local desc = {}
        for _, descendant in ipairs(self:GetDescendants()) do
            if descendant:IsA(classname) then
                table.insert(desc, descendant)
            end
        end
        return desc
    end,
    WaitForChildOfClass = function(self, classname, timeout)
        local disabled = false
        local cn = self.ChildAdded:Connect(function(child)
            if child:IsA(classname) then
                cn:Disconnect()
                disabled = true
                return child
            end
        end)
        task.wait(timeout)
        if not disabled then
            cn:Disconnect()
        end
    end,
    WaitForDescendantOfClass = function(self, classname, timeout)
        local disabled = false
        local cn = self.DescendantAdded:Connect(function(child)
            if child:IsA(classname) then
                cn:Disconnect()
                disabled = true
                return child
            end
        end)
        task.wait(timeout)
        if not disabled then
            cn:Disconnect()
        end
    end,
    GetFullName = function(self)
        local current = self.Parent
        local result = self.Name
        while current do
            result = current.Name .. '.' .. result
        end
        return result
    end,
    TweenProperties = function(self, target, t, easingDir, easingStyle)
        TS:Create(
            self,
            TweenInfo.new(
                t,
                easingStyle or Enum.EasingStyle.Quad,
                easingDir or Enum.EasingDirection.InOut,
                0,
                false,
                0
            ),
            target
        ):Play()
    end,
    Raycast = function(self, dist, offset)
        local offset = offset or CFrame.new()
        return raycast(self.CFrame.Position + offset.Position, (self.CFrame * offset).LookVector, dist)
    end
}



function setpartdestroyheight(n)
    W.FallenPartsDestroyHeight = n or -500
end

function setgravity(n)
    W.Gravity = n or 196.2
end

function ispointinfrontofcamera(point)
    local cameraPosition = CCM.Position
    local cameraDirection = CCM.CFrame.LookVector
    local vectorToPoint = point - cameraPosition
    local dotProduct = vectorToPoint:Dot(cameraDirection)
    return dotProduct > 0
end

function closestpointtoline(points, linePoint, lineDirection)
    local minDistance = math.huge
    local closestPoint = nil
    
    for _, point in ipairs(points) do
        if ispointinfrontofcamera(point) then
            local distance = pointToLineDistance(point, linePoint, lineDirection)
            if distance < minDistance then
                minDistance = distance
                closestPoint = point
            end
        end
    end
    
    return closestPoint, minDistance
end

function getclosestplayerbydist()
    if not LCHR then return end
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, player in pairs(PLRS:GetPlayers()) do
        if player ~= LPLR and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LCHR.hrp.Position).magnitude
            if distance < shortestDistance then
                closestPlayer = player
                shortestDistance = distance
            end
        end
    end
    return closestPlayer
end

function getclosestplayerbylook()
    local cameraPosition = CCM.CFrame.Position
    local cameraDirection = CCM.CFrame.LookVector
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

function raycast(origin, dir, lim)
    if lim then
        local dir = dir.Unit
    end
    local lim = lim or 1
    return W:RayCast(origin, dir * lim)
end

function callall(t, ...)
    for _, callback in ipairs(t) do
        callback(...)
    end
end


---


function debounce(limit, callback)
    local lastexec = time()
    return function(...)
        if lastexec - time() < 0 then
            callback(...)
            lastexec = limit
        end
    end
end

function promise(func)
    local promiseobj = {
        sucalls = {},
        facalls = {},
        calls = {},
        status = 'pending'
    }
    function promiseobj.Then(self, callback)
        table.insert(self.calls, callback)
    end
    function promiseobj.Resolve(self, callback)
        table.insert(self.sucalls, callback)
    end
    function promiseobj.Fail(self, callback)
        table.insert(self.facalls, callback)
    end
    local function call(s, r)
        if s then
            callall(promiseobj.sucalls, r)
        else
            callall(promiseobj.facalls, r)
        end
        callall(promiseobj.calls, r, promiseobj.status) 
    end
    task.spawn(function()
        local s, r = pcall(func)
        if s then
            promiseobj.status = 'success'
        else
            promiseobj.status = 'fail'
        end
        call(s, r)
    end)
    return promiseobj
end

function callintervalp(t, callback)
    local enabled = true
    task.spawn(function()
        while task.wait(t) and enabled do
            callback()
        end
    end)
    return function()
        enabled = false
    end
end

function callinterval(t, callback)
    local enabled = true
    while task.wait(t) and enabled do
        callback(function()
            enabled = false
        end)
    end
end


---


local unhooks = {}
local properties = {}

function hooknamecall(class, callback, interrupt)
    local interrupt = interrupt or false
    local metatable = getrawmetatable(class)
    setreadonly(metatable, false)
    local originalNC = metatable.__namecall
    metatable.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local result = callback(self, method, ...)
        if not interrupt then
            return originalNC(self, ...)
        end
        return result 
    end)
    local function unhook()
        setreadonly(metatable, false)
        metatable.__namecall = originalMC
        setreadonly(metatable, true)
    end
    table.insert(unhooks, unhook)
    setreadonly(metatable, true) 
    return unhook
end

function hookmethod(class, method, callback, interrupt)
    local interrupt = interrupt or false
    local metatable = getrawmetatable(class)
    setreadonly(metatable, false)
    local originalNC = metatable.__namecall
    metatable.__namecall = newcclosure(function(self, ...)
        local callmethod = getnamecallmethod()
        if callmethod == method then
            local result = callback(self, callmethod, ...)
            if interrupt then
                return result
            end
        end
        return originalNC(self, ...)
    end)
    local function unhook()
        setreadonly(metatable, false)
        metatable.__namecall = originalMC
        setreadonly(metatable, true)
    end
    table.insert(unhooks, unhook)
    setreadonly(metatable, true)
    return unhook
end

function hookproperty(instance, property, callback)
    properties[instance] = {
        cv = instance[property],
        get = function()
            return instance[proeprty]
        end,
        cb = callback
    }
    return function()
        local idx = 0
        for i, _ in pairs(properties) do
            idx += 1
            if i == instance then
                table.remove(properties, idx)
                break
            end
        end
    end
end


local mt = getrawmetatable(game)
local origidx = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(t, key)
    local value = custom[key]
    if value then
        return value
    end
    return origidx(t, key)
end)
setreadonly(mt, true)

local rsCn
getgenv().__end = function()
    rsCn:Disconnect()
    setreadonly(mt, false)
    mt.__index = origidx
    setreadonly(mt, true)
    for _, unhook in ipairs(unhooks) do
        unhook()
    end
    getgenv().__end = nil
end

tick = 0
timesinceexec = 0

rsCn = game['Run Service'].RenderStepped:Connect(function(dt)
    tick += 1
    timesinceexec += dt
    MS = LPLR:GetMouse()
    CCM = W.CurrentCamera
    local humanoid = LPLR.Character and LPLR.Character:FindFirstChildOfClass('Humanoid')
    local hrp = LPLR.Character and LPLR.Character:FindFirstChild('HumanoidRootPart')
    if humanoid and not humanoid.Health == 0 and hrp then
        LCHR = {
            model = LPLR.Character,
            hrp = hrp,
            humanoid = humanoid
        }
    else
        LCHR = nil
    end
    for i, info in ipairs(properties) do
        local val = info.get()
        if info.cv ~= val then
            info.callback(i, info.cv, val)
            info.cv = val
        end
    end
end)


globalizeItems(getfenv()) 
