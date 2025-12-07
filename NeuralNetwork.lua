

--[[

lua-luau hybrid code.

all use x = x + y instead of x += y

if on lua:
random seed set
table.create created
savefile created
JSON Encode/Decode created (fake json)

if on luau:
savefile = writefile

]]

local coeff = 0.044715
local coeff3 = coeff * 3
local s2op = math.sqrt(2 / math.pi)

math.randomseed(os and os.time() or 0)

local function GELU(x)
    local inner = s2op * (x + coeff * x * x * x))
    return x / 2 * (1 + math.tanh(inner))
end
local function dGELU(x)
    local x_sq = x * x
    local inner = s2op * (x + coeff * x_sq * x)
    local tanh_inner = math.tanh(inner)
    
    local sech_sq = 1 - (tanh_inner * tanh_inner)
    local inner_deriv = s2op * (1 + coeff3 * x_sq)
    
    return (1 + tanh_inner) / 2 + (0.5 * x * sech_sq * inner_deriv)
end
    
table.create = table.create or function(count, value)
    local value = value or 0
    local t = {}
    for i = 1, count do
        t[i] = value
    end
    return t
end

local savefile = game and writefile or function(path, content)
    local file, err = io.open(path,'w')
    if not file then error('couldnt save file: '..err) return end
    file:write(content)
    file:close()
end

local hs = game and game:GetService('HttpService') or {
    JSONEncode = function(self, t)
        local parts = {}
        for k, v in pairs(t) do
            local key = type(k) == 'number' and k or string.format('%q', k)
            local value
            if type(v) == 'table' then
                value = self:JSONEncode(v)
            elseif type(v) == 'string' then
                value = string.format('%q', v)
            else -- numbarr
                value = tostring(v)
            end
            table.insert(parts, string.format('[%s]=%s', key, value))
        end
        return '{' .. table.concat(parts, ',') .. '}'
    end,
    
    JSONDecode = function(_, str)
        local chunk, err = load('return ' .. str)
        if not chunk then
            error('JSON decode error: ' .. err)
        end
        return chunk()
    end
}




local NN = {}
NN.__index = NN
function NN.new(num_inputs, sizes)
    
    if sizes == nil then
        return setmetatable(num_inputs, NN)
    end 

    local self = setmetatable({},NN)
    
    self.sizes = sizes
    self.layers = table.create(#sizes+2) -- hidden + input and output
    
    self.weight_counters = table.create(#sizes)
    self.bias_counters = table.create(#sizes)
    
    --[[
    l {  <-- old
        {
         {weights = num_inputs * num_neurons},
         {biases = num_neurons}
        }
    }
    ->
    l {  <-- new
      {
        biases = num_neurons, -- unpack
        weights = num_inputs * num_neurons -- unpack
      }
    }
    ]]

    for index, num_neurons in ipairs(sizes) do
        local num_inputs = sizes[index-1] or num_inputs
        
        local num_weights = num_inputs * num_neurons
        local num_biases = num_neurons
        
        self.weight_counters[index] = num_weights
        self.bias_counters[index] = num_biases
        
        local weights = table.create(num_weights)
        local biases = table.create(num_biases)
        
        for i=1,num_weights do
            weights[i]=(math.random()-0.5)*5 
        end
        for i=1,num_biases do
            biases[i]=(math.random()-0.5)*5
        end
        
        --[[ old -> nested tables
        self.layers[index] = {
            weights, biases
        }
        ]]
        -- new -> single table
        self.layers[index] = {
            table.unpack(biases),
            table.unpack(weights)
        }
    end
    
    return self
end

function NN:getdata()
    local data = {}
    for k, v in pairs(self) do
        if type(v) ~= 'function' then
            data[k] = v
        end
    end
    return data
end

function NN:mutate(rate)
    for index, _ in ipairs(self.sizes) do
        local num_weights = self.weight_counters[index]
        local num_biases = self.bias_counters[index]
        local layer = self.layers[index]
        
        for i=1, num_weights do
            layer[i+num_biases] = layer[i+num_biases] + (math.random()-0.5)*rate
        end 
        for i=1, num_biases do
            layer[i] = layer[i] + (math.random()-0.5)*rate
        end
    end
    return self
end

-- ngl this corr function was made by AI
-- my brain isnt big enough for ts
function NN:corr(inputs, expect, rate)
    local capture = self:ff(inputs, true)
    local next_deltas = {}
    
    for index = #self.sizes, 1, -1 do
        local num_neurons = self.sizes[index]
        local num_biases = self.bias_counters[index]
        local layer = self.layers[index]
        
        local this_input = index == 1 and inputs or capture[index-1]
        local num_inputs = #this_input
        
        local current_deltas = table.create(num_neurons)
        
        for neuron_index = 1, num_neurons do
            local weights_index = (neuron_index-1) * num_inputs + num_biases
            local bias_index = neuron_index
            local bias = layer[bias_index]
            local weighted_sum = 0
            
            for i, input in ipairs(this_input) do
                weighted_sum = weighted_sum + layer[i+weights_index] * input
            end
            
            local error_val = 0
            if index == #self.sizes then
                error_val = capture[index][neuron_index] - expect[neuron_index]
            else
                local next_layer = self.layers[index+1]
                local next_num_neurons = self.sizes[index+1]
                local next_num_biases = self.bias_counters[index+1]
                
                for next_neuron_index = 1, next_num_neurons do
                    local next_weights_index = (next_neuron_index-1) * num_neurons + next_num_biases
                    local connecting_weight = next_layer[neuron_index + next_weights_index]
                    
                    error_val = error_val + next_deltas[next_neuron_index] * connecting_weight
                end
            end
            
            local delta = error_val * dGELU(weighted_sum + bias)
            current_deltas[neuron_index] = delta
            
            layer[bias_index] = layer[bias_index] - rate * delta
            
            for i, input in ipairs(this_input) do
                local w_pos = i + weights_index
                layer[w_pos] = layer[w_pos] - rate * delta * input
            end
        end
        
        next_deltas = current_deltas
    end
end

function NN:ff(inputs, capture)
    local capture = capture and table.create(#self.sizes)
    local this_input = inputs
    for index, num_neurons in ipairs(self.sizes) do
        local num_weights = self.weight_counters[index]
        local num_biases = self.bias_counters[index]
        local layer = self.layers[index]
        
        local this_output = table.create(num_neurons)
        local num_inputs = #this_input
        
        for neuron_index=1, num_neurons do
            local weights_index = (neuron_index-1) * num_inputs + num_biases
            local bias_index = neuron_index
            local bias = layer[bias_index]
            local weighted_sum = 0
            for i, input in ipairs(this_input) do
                weighted_sum = weighted_sum + layer[i+weights_index] * input
            end
            this_output[neuron_index] = GELU(weighted_sum+bias)
        end
        if capture then
            capture[index] = this_output
        end
        this_input = this_output
    end
    return capture and capture or this_input
end

function NN:save(path)
    local data = hs:JSONEncode(self:getdata())
    savefile(path, data)
    return self
end

function NN.load(path)
    return NN.new(hs:JSONDecode(loadfile(path)()))
end

return NN
