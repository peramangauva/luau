--!strict
--!optimize 2

Mod = {}

type Argument = string | number | nil
type CommandBody = {
    Raw: string,
    Args: {Argument},
    Full: string
}
type TextCommand = {
    Name: string,
    Body: CommandBody
}
type TextMessage = {
    Sender: Player,
    Text: string
}

plrs = game:GetService('Players')
tcs = game:GetService('TextChatService')
me = plrs.LocalPlayer
senv = getfenv()
genv = getgenv()
env = setmetatable({},{__index=function(_,k)
    return senv[k] or genv[k]
end})
Whitelist = {me}

Commands = {
    ['!'] = {
        Prefix = '',
        RequireSpace = false,
        Callback = function(Body)
            Mod.Connection:Disconnect()
            print('exited')
        end
    },
    ['='] = {
        Prefix = '',
        RequireSpace = false,
        Callback = function(Body)
            local code = Body.Raw
            local result, err = loadstring(code)
            if not result then
                return warn(err)
            end
            setfenv(result, env)
            local success, result = xpcall(result, debug.traceback)
            if not success then
                warn(result)
            end
        end
    }
}

function GetCommand(raw: string): TextCommand?
    local isCommand: boolean = false
    local cmdName: string = ''
    local lenCommand: number = 0
    for name, data in pairs(Commands) do
        local command: string = (data.Prefix or '')..name..(data.RequireSpace and ' ' or '')
        lenCommand = #command
        local start: string = raw:sub(1, lenCommand)
        if start == command then
            cmdName = name
            isCommand = true
            break
        end
    end
    if isCommand then
        local rest: string = raw:sub(lenCommand+1):match('^%s*(.-)%s*$')
        local args: {Argument} = {}
        for _, value in ipairs(rest:split('&')) do
            local value: Argument = value:match('^%s*(.-)%s*$')
            local r: Argument
            local num: number? = tonumber(value)
            if value == '' or value == 'nil' then
                r = nil
            elseif num then
                r = num
            else
                r = value
            end
            table.insert(args, r)
        end
        local body: CommandBody = {
            Raw = rest,
            Args = args,
            Full = raw
        }
        local command: TextCommand = {
            Name = cmdName,
            Body = body
        }
        return command
    end
end

function ExecuteCommand(command: TextCommand)
    local callback = Commands[command.Name].Callback
    callback(command.Body)
end

function ProcessChatMessage(text: TextMessage)
    --print(text.Sender.Name, 'said', text.Text)
end

local Connection = tcs.MessageReceived:Connect(function(msg: TextChatMessage)
    local sender: Player? = msg.TextSource and plrs:GetPlayerByUserId(msg.TextSource.UserId)
    local raw: string = msg.Text:gsub('&lt;', '<')
        :gsub('&gt;', '>')
        :gsub('&quot;', '"')
        :gsub('&apos;', "'")
        :gsub('&amp;', '&')
    
    if table.find(Whitelist, sender) then
        local command: TextCommand = GetCommand(raw)
        if command then
            ExecuteCommand(command)
            return
        end
    end
    local text: TextMessage = {
        Sender = sender, Text = raw
    }
    ProcessChatMessage(text)
end)

Mod.tcs = tcs
Mod.senv = senv
Mod.Commands = Commands
Mod.Whitelist = Whitelist
Mod.Connection = Connection
Mod.GetCommand = GetCommand
Mod.ExecuteCommand = ExecuteCommand
Mod.ProcessChatMessage = ProcessChatMessage

return Mod
