
local ACTIVATION_RESPONSE = 1

local NeuralNetwork = {
    transfer = function(x)
        return 1 / (1 + math.exp(-x / ACTIVATION_RESPONSE))
    end -- Sigmoid transfer function
}

function NeuralNetwork.create(_numInputs, _numOutputs, _numHiddenLayers, _neuronsPerLayer, _learningRate)
    _numInputs = _numInputs or 1
    _numOutputs = _numOutputs or 1
    _numHiddenLayers = _numHiddenLayers or math.ceil(_numInputs / 2)
    _neuronsPerLayer = _neuronsPerLayer or math.ceil(_numInputs * 0.66666 + _numOutputs)
    _learningRate = _learningRate or 0.5

    -- Initialize network with learning rate
    local network = setmetatable({ learningRate = _learningRate }, { __index = NeuralNetwork })

    -- Input Layer
    network[1] = {}
    for i = 1, _numInputs do
        network[1][i] = {}
    end

    -- Hidden and Output Layers
    for i = 2, _numHiddenLayers + 2 do -- +2 for hidden layers and output layer
        network[i] = {}
        local neuronsInLayer = (i == _numHiddenLayers + 2) and _numOutputs or _neuronsPerLayer

        for j = 1, neuronsInLayer do
            network[i][j] = { bias = math.random() * 2 - 1 }
            local numNeuronInputs = #network[i - 1]

            for k = 1, numNeuronInputs do
                network[i][j][k] = math.random() * 2 - 1 -- Initialize weights between -1 and 1
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

    -- Set input layer results
    for j = 1, #self[1] do
        self[1][j].result = inputs[j]
    end

    -- Forward propagate through hidden and output layers
    for i = 2, #self do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            local sum = neuron.bias
            local prevLayer = self[i - 1]

            for k = 1, #prevLayer do
                sum = sum + (neuron[k] * prevLayer[k].result)
            end

            neuron.result = self.transfer(sum)

            -- Collect output layer results
            if i == #self then
                self.outputs = self.outputs or {}
                self.outputs[j] = neuron.result
            end
        end
    end

    -- Return a copy of outputs to prevent external modification
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

    self:forward(inputs) -- Forward pass to compute current outputs

    -- Calculate deltas for output and hidden layers
    for i = #self, 2, -1 do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            if i == #self then
                -- Output layer delta
                neuron.delta = (desiredOutputs[j] - neuron.result) * neuron.result * (1 - neuron.result)
            else
                -- Hidden layer delta
                local deltaSum = 0
                local nextLayer = self[i + 1]
                for k = 1, #nextLayer do
                    deltaSum = deltaSum + (nextLayer[k][j] * nextLayer[k].delta)
                end
                neuron.delta = neuron.result * (1 - neuron.result) * deltaSum
            end
        end
    end

    -- Update weights and biases
    for i = 2, #self do
        for j = 1, #self[i] do
            local neuron = self[i][j]
            -- Update bias
            neuron.bias = neuron.bias + (neuron.delta * self.learningRate)

            -- Update weights
            for k = 1, #self[i - 1] do
                neuron[k] = neuron[k] + (neuron.delta * self.learningRate * self[i - 1][k].result)
            end
        end
    end
end

return NeuralNetwork
