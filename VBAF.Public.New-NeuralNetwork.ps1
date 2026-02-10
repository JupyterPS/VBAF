    function New-VBAFNeuralNetwork {
    <#
    .SYNOPSIS
        Creates a new multi-layer neural network.
    
    .DESCRIPTION
        Creates a fully-connected feedforward neural network with backpropagation.
        The network can learn from labeled data using gradient descent.
        
        Built from scratch in PowerShell 5.1 - no external ML libraries!
    
    .PARAMETER Architecture
        Array of integers defining network structure.
        Example: @(2, 4, 1) creates:
        - Input layer: 2 neurons
        - Hidden layer: 4 neurons
        - Output layer: 1 neuron
    
    .PARAMETER LearningRate
        Learning rate (alpha) for gradient descent.
        Typical values: 0.01 to 0.5
        Default: 0.1
        
        Higher = faster learning but less stable
        Lower = slower learning but more stable
    
    .PARAMETER Activation
        Activation function to use for hidden layers.
        Valid values: 'Sigmoid', 'ReLU', 'Tanh'
        Default: 'Sigmoid'
        
        - Sigmoid: Smooth, outputs 0-1, good for classification
        - ReLU: Fast, works well for deep networks
        - Tanh: Outputs -1 to 1, zero-centered
    
    .PARAMETER OutputActivation
        Activation function for output layer.
        Valid values: 'Sigmoid', 'ReLU', 'Tanh', 'Linear'
        Default: 'Sigmoid'
        
        - Use 'Sigmoid' for binary classification (0-1 output)
        - Use 'Linear' for regression (any output value)
    
    .PARAMETER Seed
        Random seed for weight initialization.
        Use same seed for reproducible results.
        Default: Random
    
    .EXAMPLE
        # Simple XOR network
        $nn = New-VBAFNeuralNetwork -Architecture @(2, 3, 1) -LearningRate 0.5
        
        # Train on XOR data
        $xorData = @(
            @{Input=@(0,0); Expected=@(0)},
            @{Input=@(0,1); Expected=@(1)},
            @{Input=@(1,0); Expected=@(1)},
            @{Input=@(1,1); Expected=@(0)}
        )
        
        for ($epoch = 0; $epoch -lt 1000; $epoch++) {
            foreach ($sample in $xorData) {
                $output = $nn.Forward($sample.Input)
                $nn.Backward($sample.Expected)
            }
        }
        
    .EXAMPLE
        # Larger network for MNIST-style digit recognition
        $nn = New-VBAFNeuralNetwork -Architecture @(784, 128, 64, 10) -LearningRate 0.01 -Activation ReLU
        
        # 784 inputs (28x28 image)
        # 128 hidden neurons (first layer)
        # 64 hidden neurons (second layer)
        # 10 outputs (digits 0-9)
    
    .EXAMPLE
        # Regression network (predict continuous values)
        $nn = New-VBAFNeuralNetwork -Architecture @(5, 10, 1) -OutputActivation Linear
        
        # 5 input features
        # 10 hidden neurons
        # 1 continuous output value
    
    .OUTPUTS
        NeuralNetwork object with methods:
        - Forward($inputs) - Compute output
        - Backward($expected) - Backpropagation
        - Train($data, $epochs) - Training loop
        - Predict($inputs) - Inference
        - GetWeights() - Export weights
        - SetWeights($weights) - Import weights
    
    .NOTES
        Author: Henning
        Part of VBAF Module
        Requires: PowerShell 5.1+
        
    .LINK
        https://github.com/henning/vbaf
        
    .LINK
        Train-VBAFNeuralNetwork
        Test-VBAFNeuralNetwork
        Export-VBAFNeuralNetwork
    #>
    
    [CmdletBinding()]
    #[OutputType([NeuralNetwork])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]

        [int[]]$Architecture,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 10.0)]
        [double]$LearningRate = 0.1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Sigmoid', 'ReLU', 'Tanh')]
        [string]$Activation = 'Sigmoid',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Sigmoid', 'ReLU', 'Tanh', 'Linear')]
        [string]$OutputActivation = 'Sigmoid',
        
        [Parameter(Mandatory = $false)]
        [int]$Seed = -1
    )
    
    begin {
        # Validate Architecture
        if ($Architecture.Count -lt 2) {
            throw "Architecture must have at least 2 layers (input and output)"
        }
        if ($Architecture | Where-Object { $_ -lt 1 }) {
            throw "Each layer must have at least 1 neuron"
        }
        Write-Verbose "Creating neural network with architecture: $($Architecture -join ' → ')"
        Write-Verbose "Learning rate: $LearningRate"
        Write-Verbose "Activation: $Activation"
        Write-Verbose "Output activation: $OutputActivation"
    }
    
    process {
        try {
            # Set random seed if specified
            if ($Seed -ge 0) {
                Get-Random -SetSeed $Seed
                Write-Verbose "Random seed set to: $Seed"
            }
            
            # Create the neural network
            # Note: The NeuralNetwork class constructor takes (architecture, learningRate)
            # Activation function selection is handled internally
            $network = New-Object NeuralNetwork -ArgumentList (,$Architecture), $LearningRate
            
            Write-Verbose "✓ Neural network created successfully"
            Write-Verbose "  Total layers: $($Architecture.Count)"
            Write-Verbose "  Input neurons: $($Architecture[0])"
            Write-Verbose "  Output neurons: $($Architecture[-1])"
            
            # Calculate total parameters (weights + biases)
            $totalParams = 0
            for ($i = 0; $i -lt $Architecture.Count - 1; $i++) {
                $weights = $Architecture[$i] * $Architecture[$i + 1]
                $biases = $Architecture[$i + 1]
                $totalParams += $weights + $biases
            }
            Write-Verbose "  Total parameters: $totalParams"
            
            # Return the network
            return $network
            
        } catch {
            Write-Error "Failed to create neural network: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "New-VBAFNeuralNetwork completed"
    }

} 