
local SAVEPATH = 'AI.json'

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
        local chunk, err = loadstring('return ' .. str)
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
    self.layers = table.create(#sizes+2)
    
    self.weight_counters = table.create(#sizes)
    self.bias_counters = table.create(#sizes)
    
    --[[
    l {
        {
         {weights = num_inputs * num_neurons},
         {biases = num_neurons}
        }
    }
    ]]

    for index, num_neurons in ipairs(sizes) do
        -- layer_size = neuron count
        
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
        
        self.layers[index] = {
            weights, biases
        }
    end
    
    return self
end

function NN:getdata()
    local data = {}
    for k, v in pairs(self) do
        if typeof(v) ~= 'function' then
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
        local weights = layer[1]
        local biases = layer[2]
        
        for i=1, num_weights do
            weights[i] = weights[i] + (math.random()-0.5)*rate
        end 
        for i=1, num_biases do
            biases[i] = biases[i] + (math.random()-0.5)*rate
        end
    end
end

function NN:ff(inputs)
    local this_input = inputs
    for index, num_neurons in ipairs(self.sizes) do
        local num_weights = self.weight_counters[index]
        local num_biases = self.bias_counters[index]
        local layer = self.layers[index]
        local weights = layer[1]
        local biases = layer[2]
        
        local this_output = table.create(num_neurons)
        local num_inputs = #this_input
        
        for neuron_index=1, num_neurons do
            local weights_index = (neuron_index-1) * num_inputs
            local bias_index = neuron_index
            local bias = biases[bias_index]
            local weighted_sum = 0
            for i, input in this_input do
                weighted_sum = weighted_sum + weights[i+weights_index] * input
            end
            this_output[neuron_index] = math.max(0, weighted_sum + bias)
        end
        
        this_input = this_output
    end
    return this_input
end

function NN:save()
    writefile(SAVEPATH, hs:JSONEncode(self:getdata()))
end

function NN.load()
    return NN.new(hs:JSONDecode(readfile(SAVEPATH)()))
end
