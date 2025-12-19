--!strict

local Mod = {}

type CommandBody = {
    Raw: string?,
    Args: {string?},
    Full: string
}
type TextCommand = {
    Command: string,
    Body: CommandBody?
}
type TextMessage = {
    Sender: Player,
    Text: string
}

local plrs = game:GetSercice('Players')
local tcs = game:GetService('TextChatService')
local env = getfenv()

local me: Player = plrs.LocalPlayer

local Whitelist: {Player} = {me}
local Commands = {
    ['test'] = {
        Prefix = '--!',
        RequireSpace = true
        Callback = function(Body)
            print('called t1')
            print('full:',Body.Full)
            print('raw:',Body.raw)
            print('arg1:',Body.Args[1])
            print('arg2:',Body.Args[2])
        end
    },
    ['test2'] = {
        Prefix = 'wa',
        RequireSpace = false
        Callback = function(Body)
            print('called t2')
            print('full:',Body.Full)
            print('raw:',Body.raw)
            print('arg1:',Body.Args[1])
            print('arg2:',Body.Args[2])
        end
    }
}

local function GetCommand(raw: string) -> TextCommand?
    local result: TextCommand?
    local lenCommand: number?
    for name, data in pairs(Commands) do
        local command: string = (data.Prefix or '')..name..(data.RequireSpace and ' ' or '')
        lenCommand = #command
        local start: string = raw:sub(1, lenCommand)
        if start == command then
            result = {
                Command = name,
                Body = nil
            }
            break
        end
    end
    if result then
        local rest: string = raw:sub(lenCommand)
        local args: {string | number | nil} = {}
        for _, value in ipairs(rest:split('&')) do
            local value: string | number | nil = value:match('^%s*(.-)%s*$')
            local r: string | number | nil
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
        result.Body = body
    end
    return result
end

local function ExecuteCommand(command: TextCommand)
    local callback: () -> nil = Commands[command.Name].Callback
    callback(command.Body)
end

local function processChatMessage(text: TextMessage)
    print(text.Sender.Name, 'said', text.Text)
end

local Connection = tcs.MessageReceived:Connect(function(msg: TextChatMessage)
    local sender: Player? = msg.TextSource & plrs:GetPlayerByUserId(msg.TextSource.UserId)
    local raw: string = msg.Text:gsub('&lt;', '<')
        :gsub('&gt;', '>')
        :gsub('&quot;', '"')
        :gsub('&apos;', "'")
        :gsub('&amp;', '&'))
    
    if table.find(sender, Whitelist) then
        local command: TextCommand = GetCommand(raw)
        if command then
            ExecuteCommand(command)
            return
        end
    end
    local text: TextMessage = {
        Sender = sender, Text = raw
    }
    processChatMessage(text)
end)

Mod.tcs = tcs,
Mod.Commands = Commands
Mod.GetCommand = GetCommand
Mod.ExecuteCommand = ExecuteCommand
Mod.Connection = Connection

return Mod