--[[
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
sus - sex


Instance methods:

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


functions:

globalizeItems(Table)
hooknamecall(Class, Callback [, Interrupt])
hookmethod(Class, Method, Callback [, Interrupt])


if u dont understand goto2
only use it if you have network ownership
of the part. then other players will see it move

]]

if getgenv().__loaded then
    getgenv().__end()
	getgenv().__end = nil
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
    RUNS = game['Run Service'],
    RS = game.ReplicatedStorage,
    LPLR = game.Players.LocalPlayer,
    LCHR = game.Players.LocalPlayer.Character,
    CCM = workspace.CurrentCamera
    sus = 'sex'
}

globalizeItems(globalVars)


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
    end 
}

local unhooks = {}

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
    table.insert(unhooks, function()
        setreadonly(metatable, false)
        metatable.__namecall = originalMC
        setreadonly(metatable, true)
    end)
    setreadonly(metatable, true) 
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
    table.insert(unhooks, function()
        setreadonly(metatable, false)
        metatable.__namecall = originalMC
        setreadonly(metatable, true)
    end)
    setreadonly(metatable, true)
end

local mt = getrawmetatable(Instance)
local origidx = mt.__index
setreadonly(mt, false)
for mname, f in pairs(custom) do
    mt.__index[mname] = mt.__index[mname] or f
end
setrawmetatable(Instance, mt)
setreadonly(mt, true)

getgenv().__end = function()
    rsCn:Disconnect()
    setreadonly(mt, false)
    mt.__index = origidx
    setreadonly(mt, true)
    for _, unhook in ipairs(unhooks) do
        unhook()
    end
end

local rsCn = game['Run Service'].RenderStepped:Connect(function()
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
end)


globalizeItems(getfenv()) 
