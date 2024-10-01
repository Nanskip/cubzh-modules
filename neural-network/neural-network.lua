local ACTIVATION_RESPONSE = 1

local NeuralNetwork = {
    transfer = function(x)
        return 1 / (1 + math.exp(-x / ACTIVATION_RESPONSE))
    end
}

function NeuralNetwork.create(_numInputs, _numOutputs, _numHiddenLayers, _neuronsPerLayer, _learningRate)
    _numInputs = _numInputs or 1
    _numOutputs = _numOutputs or 1
    _numHiddenLayers = _numHiddenLayers or math.ceil(_numInputs / 2)
    _neuronsPerLayer = _neuronsPerLayer or math.ceil(_numInputs * 0.66666 + _numOutputs)
    _learningRate = _learningRate or 0.5

    local network = setmetatable({ learningRate = _learningRate }, { __index = NeuralNetwork })
    network.layers = _numHiddenLayers + 2
    network.nodes = {}

    network[1] = {}
    network.nodes[1] = _numInputs
    for i = 1, _numInputs do
        network[1][i] = {}
    end

    for i = 2, network.layers do
        network[i] = {}
        local neuronsInLayer = (i == network.layers) and _numOutputs or _numHiddenLayers
        network.nodes[i] = neuronsInLayer
        for j = 1, neuronsInLayer do
            network[i][j] = { bias = math.random() * 2 - 1 }
            local numNeuronInputs = network.nodes[i - 1]
            for k = 1, numNeuronInputs do
                network[i][j][k] = math.random() * 2 - 1
            end
        end
    end

    return network
end

function NeuralNetwork:forward(inputs)
    if type(inputs) ~= "table" then
        inputs = { inputs }
    end

    if #inputs ~= #self[1] then
        error(string.format("Neural Network received %d input(s) (expected %d)", #inputs, #self[1]), 2)
    end

    for j = 1, #self[1] do
        self[1][j].result = inputs[j]
    end

    for i = 2, #self do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            local sum = neuron.bias
            local prevLayer = self[i - 1]
            for k = 1, #prevLayer do
                sum = sum + (neuron[k] * prevLayer[k].result)
            end
            neuron.result = self.transfer(sum)
            if i == #self then
                self.outputs = self.outputs or {}
                self.outputs[j] = neuron.result
            end
        end
    end

    local outputs = {}
    for i = 1, #self[#self] do
        outputs[i] = self[#self][i].result
    end

    return outputs
end

function NeuralNetwork:backward(inputs, desiredOutputs)
    if #inputs ~= #self[1] then
        error(string.format("Neural Network received %d input(s) (expected %d)", #inputs, #self[1]), 2)
    end

    if #desiredOutputs ~= #self[#self] then
        error(string.format("Neural Network received %d desired output(s) (expected %d)", #desiredOutputs, #self[#self]), 2)
    end

    self:forward(inputs)

    for i = #self, 2, -1 do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            if i == #self then
                neuron.delta = (desiredOutputs[j] - neuron.result) * neuron.result * (1 - neuron.result)
            else
                local deltaSum = 0
                local nextLayer = self[i + 1]
                for k = 1, #nextLayer do
                    deltaSum = deltaSum + (nextLayer[k][j] * nextLayer[k].delta)
                end
                neuron.delta = neuron.result * (1 - neuron.result) * deltaSum
            end
        end
    end

    for i = 2, #self do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            neuron.bias = neuron.bias + (neuron.delta * self.learningRate)
            for k = 1, #self[i - 1] do
                neuron[k] = neuron[k] + (neuron.delta * self.learningRate * self[i - 1][k].result)
            end
        end
    end
end

function NeuralNetwork:clone()
    local newNetwork = NeuralNetwork.create(1, 1, 1, 1, self.learningRate)
    newNetwork.layers = self.layers
    newNetwork.nodes = {}
    for i = 1, self.layers do
        newNetwork.nodes[i] = self.nodes[i]
        newNetwork[i] = {}
        for j = 1, self.nodes[i] do
            newNetwork[i][j] = { bias = self[i][j].bias }
            for k = 1, self.nodes[i - 1] or 0 do
                newNetwork[i][j][k] = self[i][j][k]
            end
        end
    end
    return newNetwork
end

return NeuralNetwork
