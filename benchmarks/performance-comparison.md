# Performance Comparison

Training time and memory usage across VBAF model types.
All measurements on Windows 11, PowerShell 5.1, Intel i5, 16GB RAM.

## Training Time

| Model | Episodes/Epochs | Avg time |
|-------|----------------|----------|
| NeuralNetwork (XOR) | 1000 epochs | 2.1s |
| GaussianNaiveBayes | Single fit | < 0.1s |
| RidgeRegression | Single fit | < 0.1s |
| KMeans (k=3) | Single fit | 0.3s |
| DQN (64x64) | 100 episodes | 45-90s |
| DQN (24x24) | 100 episodes | 25-50s |

## Memory Usage

| Component | Memory |
|-----------|--------|
| VBAF.LoadAll.ps1 | ~45MB |
| DQN agent (10k replay) | ~8MB |
| Full enterprise suite | ~120MB |

## Scalability

VBAF runs on standard business hardware.
No GPU, no external packages, no internet required after install.
