
-- made by peramangauva

local coeff = 0.044715
local coeff3 = coeff * 3
local s2op = math.sqrt(2 / math.pi)

math.randomseed(os and os.time() or 0)

local function GELU(x)
    local inner = s2op * (x + coeff * x * x * x)
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
    
if not table.create then
    table.create = function(count, value)
        local value = value or 0
        local t = {}
        for i = 1, count do
            t[i] = value
        end
        return t
    end
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
function NN.new(num_inputs, sizes, momentum, friction)

    local self = setmetatable({},NN)
    
    self.momentum = momentum
    self.velocities = table.create(#sizes)
    self.friction = friction
    
    self.sizes = sizes
    self.layers = table.create(#sizes)
    self.input_sizes = {}
    
    self.input_sizes[1] = num_inputs
    for i=2, #sizes do
        self.input_sizes[i] = self.sizes[i-1]
    end
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
        
        local weights = table.create(num_weights)
        local biases = table.create(num_biases)
        
        for i=1,num_weights do
            weights[i]=(math.random()-0.5)*2
        end
        for i=1,num_biases do
            biases[i]=(math.random()-0.5)*2
        end
        
        --[[ old -> nested tables
        self.layers[index] = {
            weights, biases
        }
        ]]
        -- new -> single table
        local result = table.create(num_biases+num_weights)
        self.layers[index] = result
        
        for i, v in ipairs(biases) do
            result[i] = v
        end
        for i, v in ipairs(weights) do
            result[i+num_biases] = v
        end
        
        if momentum then
            self.velocities[index] = table.create(num_biases + num_weights)
        end
    end
    
    return self
end

function NN:from_data(data, iters, lr)
    for _=1, iters do
        for _, item in ipairs(data) do
            self:corr(item[1], item[2], lr)
        end
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
        local num_weights = self.input_sizes[index]
        local num_biases = self.sizes[index]
        local layer = self.layers[index]
        
        for i=1, num_weights*num_biases do
            layer[i+num_biases] = layer[i+num_biases] + (math.random()-0.5)*rate
        end 
        for i=1, num_biases do
            layer[i] = layer[i] + (math.random()-0.5)*rate
        end
    end
    return self
end

local function copy_table(t)
    local new = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            new[k] = copy_table(v)
        else
            new[k] = v
        end
    end
    return new
end

function NN:copy()
    local new = copy_table(self:getdata())
    setmetatable(new, NN)
    return new
end

function NN:corr(inputs, expect, rate)
    --[[
    to get bias given: nidx - neuron index
    self.layers[i][nidx]
        
    to get weight given: nidx, widx - neuron index and weight index
    self.layers[i][nn+(nidx-1)*ni+widx]
    weight start index = nn+(nidx-1)*ni
    number of weights  = ni
    ]]
    local all_outputs = self:ff(inputs, true, false)
    local next_deltas = table.create(#expect)
    
    for i=#self.sizes,1,-1 do
        local nn = self.sizes[i]
        local ni = self.input_sizes[i]
        local deltas = table.create(nn)
        if i == #self.sizes then
            for j=1, nn do
                deltas[j] = (all_outputs[i][1][j] - expect[j]) * dGELU(all_outputs[i][2][j])
            end
        else
            for j=1, nn do
                local sum = 0
                local len_nd = #next_deltas
                for k=1, len_nd do
                    local weight = self.layers[i+1][len_nd+(k-1)*nn+j]
                    sum = sum + weight * next_deltas[k]
                end
                deltas[j] = sum * dGELU(all_outputs[i][2][j])
            end
        end
        for j=1, nn do
            local change_bias
            if self.momentum then
                local grad_bias = deltas[j]
                local vel_bias = self.velocities[i][j]
                vel_bias = (self.friction * vel_bias) + (rate * grad_bias)
                self.velocities[i][j] = vel_bias
                change_bias = vel_bias
            else
                change_bias = deltas[j]*rate
            end
            self.layers[i][j] = self.layers[i][j] - change_bias
            for k=1, ni do
                local weight_idx = nn+(j-1)*ni+k
                local a
                if i == 1 then
                    a = inputs[k]
                else
                    a = all_outputs[i-1][1][k]
                end
                local change_weight
                if self.momentum then
                    local grad_weight = deltas[j] * a
                    local vel_weight = self.velocities[i][weight_idx]
                    vel_weight = (self.friction * vel_weight) + (rate * grad_weight)
                    self.velocities[i][weight_idx] = vel_weight
                    change_weight = vel_weight
                else
                    change_weight = deltas[j] * a
                end
                self.layers[i][weight_idx] = self.layers[i][weight_idx] - change_weight
            end
        end
        next_deltas = deltas
    end
    return self
end

function NN:ff(inputs, capture, passed)
    local capture = capture and table.create(#self.sizes)
    local this_input = inputs
    for i, num_neurons in ipairs(self.sizes) do
        local this_output = table.create(num_neurons)
        local nonact = table.create(num_neurons)
        for j=1, num_neurons do
            local weighted_sum = 0
            for k=1, self.input_sizes[i] do
                local weight_index = self.sizes[i]+k+self.input_sizes[i]*(j-1)
                local weight = self.layers[i][weight_index]
                -- layer[#biases + index + #weights * #currneuron-1]
                local input = this_input[k]
                weighted_sum = weighted_sum + weight * input
            end
            local bias = self.layers[i][j]
            local r = weighted_sum + bias
            nonact[j] = r
            this_output[j] = GELU(r)
        end
        if capture then
            if passed == nil then
                capture[i] = this_output
            elseif passed then
                capture[i] = nonact
            else
                capture[i] = {this_output, nonact}
            end
        end
        this_input = this_output
    end
    return capture and capture or this_input
end

function NN:save(path)
    local data = self:getdata()
    local encoded = hs:JSONEncode(data)
    if writefile then
        writefile(path, encoded)
    else
        local f, err = io.open(path, "w")
        if not f then error("save error: " .. err) end
        f:write(encoded)
        f:close()
    end

    return self
end

function NN.load(path)
    local content
    if readfile then
        content = readfile(path)
    else
        local f, err = io.open(path, "r")
        if not f then error("load error: " .. err) end
        content = f:read("*a")
        f:close()
    end
    local data = hs:JSONDecode(content)
    setmetatable(data, NN)
    return data
end

return NN
