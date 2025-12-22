--!optimize 2

if not isfolder('saved_ais') then
    makefolder('saved_ais')
end

local Module = {}

local max = math.max
local tanh = math.tanh
local sqrt = math.sqrt
local random = math.random

local tcreate = table.create

local brf32 = buffer.readf32
local bwf32 = buffer.writef32
local bru32 = buffer.readu32
local bwu32 = buffer.writeu32
local blen = buffer.len
local bcopy = buffer.copy
local bcreate = buffer.create

-- Topology = {u32} AS buffer (network size)
-- Genome = {f32} AS buffer (biases+weights)

function ReLU(x)
    return max(0, x)
end
function TableToBuffer(Table, Writer, BytesPerValue, Target)
    local TableSize = #Table
    local ByteCount = TableSize*4
    local Buffer = Target or bcreate(ByteCount)
    for i=1, TableSize do
        Writer(Buffer, (i-1)*BytesPerValue, Table[i])
    end
    return Buffer
end
function BufferToTable(Buffer, Reader, BytesPerValue, Target)
    local ByteCount = blen(Buffer)
    local ValueCount = ByteCount/BytesPerValue
    local Table = Target or tcreate(ValueCount)
    for i=1, ValueCount do
        Table[i] = Reader(Buffer, (i-1)*BytesPerValue)
    end
    return Table
end

local Manager = {}
Manager.__index = Manager
function Manager.new(Topology)
    local self = setmetatable({}, Manager)
    local MaxLayerSize = 0
    for _, LayerSize in ipairs(Topology) do
        MaxLayerSize = max(MaxLayerSize, LayerSize)
    end
    self.f32Range = 2/sqrt(Topology[1])
    local Topology = TableToBuffer(Topology, bwu32, 4)
    self.InputBuffer = bcreate(MaxLayerSize*4)
    self.OutputBuffer = bcreate(MaxLayerSize*4)
    self.Topology = Topology
    return self
end

function Manager:Genome(ParentGenome, GetBlank)
    if ParentGenome then
        local ByteCount = blen(ParentGenome)
        local Buffer = bcreate(ByteCount)
        bcopy(Buffer, 0, ParentGenome, 0, ByteCount)
        return Buffer
    end
    local ByteCount = 0
    local Topology = self.Topology
    local TopologyByteCount = blen(Topology)
    local InputSize = bru32(Topology, 0)
    for i=4, TopologyByteCount-4, 4 do
        local OutputSize = bru32(Topology, i)
        ByteCount += (InputSize+1)*OutputSize*4
        InputSize = OutputSize
    end
    local Buffer = bcreate(ByteCount)
    if not GetBlank then
        local Range = self.f32Range
        for i=0, ByteCount-4, 4 do
            bwf32(Buffer, i, (random()-0.5)*2*Range)
        end
    end
    return Buffer
end

function Manager:Breed(Parent1Genome, Parent2Genome, Strength)
    local Strength = (Strength or 0.05) * self.f32Range
    local Genome = self:Genome(nil, true)
    local ByteCount = blen(Genome)
    for i=0, ByteCount-4, 4 do
        local NewFloat
        if random() > 0.5 then
            NewFloat = brf32(Parent1Genome, i)
        else
            NewFloat = brf32(Parent2Genome, i)
        end
        NewFloat += (random()-0.5)*2*Strength
        if random() < 0.05 then
            NewFloat += (random()-0.5)*2*Strength*10
        end
        bwf32(Genome, i, NewFloat)
    end
    return Genome
end

function Manager:Feedforward(Genome, Inputs)
    local InputBuffer = self.InputBuffer
    local OutputBuffer = self.OutputBuffer
    TableToBuffer(Inputs, bwf32, 4, InputBuffer)
    local Topology = self.Topology
    local TopologyByteCount = blen(Topology)
    local LastLayerSize = bru32(Topology, 0)
    local Offset = 0
    local Limit = TopologyByteCount-4
    local Activation = ReLU
    for i=4, Limit, 4 do
        local LayerSize = bru32(Topology, i)
        local NeuronOffset = 0
        if i == Limit then
            Activation = tanh
        end
        for j=0, LayerSize*4-4, 4 do
            local Start = Offset + NeuronOffset
            local Bias = brf32(Genome, Start)
            local Result = Bias
            for k = 1, LastLayerSize do
                local ByteOffset = (k-1)*4
                local Weight = brf32(Genome, Start+4+ByteOffset)
                local Input = brf32(InputBuffer, ByteOffset)
                Result += Weight * Input
            end
            Result = Activation(Result)
            bwf32(OutputBuffer, j, Result)
            NeuronOffset += (LastLayerSize+1)*4
        end
        bcopy(InputBuffer, 0, OutputBuffer, 0, LayerSize * 4)
        LastLayerSize = LayerSize
        Offset += NeuronOffset
    end
    local NumNeurons = bru32(Topology, blen(Topology)-4)
    local Output = tcreate(NumNeurons)
    for i=1, NumNeurons do
        Output[i] = brf32(OutputBuffer, (i-1)*4)
    end
    return Output
end

function Manager:Save(Genome, file)
    writefile('saved_ais/'..file, buffer.tostring(Genome))
end
function Manager:Load(file)
    return buffer.fromstring(readfile('saves_ais/'..file))
end

Module.Manager = Manager
Module.BufferToTable = BufferToTable
Module.TableToBuffer = TableToBuffer

return Module