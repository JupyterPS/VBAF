 # VBAF: Visual Business Automation Framework

**A Machine Learning Framework for PowerShell**`n*Focus: Neural Networks & Reinforcement Learning*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/powershell/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/VBAF.svg)](https://www.powershellgallery.com/packages/VBAF)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/VBAF.svg)](https://www.powershellgallery.com/packages/VBAF)
[![GitHub stars](https://img.shields.io/github/stars/JupyterPS/VBAF.svg)](https://github.com/JupyterPS/VBAF/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/JupyterPS/VBAF.svg)](https://github.com/JupyterPS/VBAF/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

---

## Abstract

Reinforcement learning (RL) has transformative potential for business process automation, yet remains largely inaccessible to practitioners outside specialized machine learning roles. Existing RL frameworks (TensorFlow, PyTorch) prioritize computational performance over pedagogical clarity, creating steep learning curves that exclude IT professionals, business analysts, and students without extensive Python or ML backgrounds.

**VBAF (Visual Business Automation Framework)** addresses this gap by implementing neural networks, Q-learning, and multi-agent systems from first principles in PowerShell 5.1. The framework deliberately favors **educational transparency over computational performance**, making RL concepts observable, understandable, and immediately applicable to business automation scenarios.

### Key Contributions

1. **Pedagogical RL Implementation**: Complete neural network and Q-learning implementations in readable PowerShell, exposing algorithmic details typically hidden in optimized libraries.

2. **Real-Time Visual Learning**: Three integrated dashboards that visualize learning dynamics, network activations, and multi-agent interactions in real-time, transforming the "black box" of RL into an observable educational tool.

3. **Business-Focused Applications**: Multi-agent market simulation demonstrating emergent competitive behaviors (price coordination, market segmentation) without explicit inter-agent communication.

4. **Accessibility**: Implements RL in PowerShell (deployed on 50M+ Windows systems), making advanced ML techniques accessible to IT professionals already familiar with automation scripting.

---


---

## Roadmap

VBAF follows an 8-phase development roadmap. [View the full roadmap ?](https://github.com/users/JupyterPS/projects/2)

### Phase 1: Foundation (Complete)
- Neural networks with backpropagation
- Q-Learning reinforcement learning
- Interactive visualization dashboard

### Phase 2: Stability & Polish (v1.0.x) - *Current Focus*
- Comprehensive testing suite
- Performance optimization
- Enhanced error handling
- Expanded documentation

### Phase 3: RL Expansion (v1.1.0)
- PPO (Proximal Policy Optimization)
- A3C (Asynchronous Advantage Actor-Critic)
- DQN (Deep Q-Network)
- Standardized RL environments

### Phase 4: Supervised Learning (v1.2.0)
- Linear & logistic regression
- Decision trees & random forests
- Clustering algorithms (K-Means, DBSCAN)
- Naive Bayes classifier

### Phase 5: Data Pipeline (v1.3.0)
- Data preprocessing utilities
- Feature engineering tools
- Multi-format import/export
- Time series processing

### Phase 6: Deep Learning (v2.0.0)
- Convolutional Neural Networks (CNN)
- Recurrent architectures (RNN/LSTM/GRU)
- Autoencoders & VAE
- Transfer learning support

### Phase 7: Production Features (v2.1.0+)
- Model serialization & versioning
- REST API deployment
- MLOps pipeline integration
- Model interpretability tools
- AutoML capabilities

### Phase 8: Community & Ecosystem (Ongoing)
- Tutorial series & examples
- Community templates
- PowerShell ecosystem integration
- Conference presentations

**Want to contribute?** Check our [Project Board](https://github.com/users/JupyterPS/projects/2) to see what's being worked on!
## Quick Start

## Installation

### Option 1: PowerShell Gallery
Install directly from PowerShell Gallery:
```powershell
Install-Module VBAF -Scope CurrentUser
Import-Module VBAF
```
That's it! All functions are now available.

### Option 2: Clone Repository
Then choose your loader:
```powershell
# Enterprise Automation Engine (full - all pillars)
. .\VBAF.LoadAll.ps1

# Core Framework only (algorithms, ML, RL - no Enterprise pillars)
. .\VBAF.LoadCore.ps1
```
That's it! All functions are now available.

### Manual Installation (For Development)

If you want to contribute or modify VBAF:
```powershell
# Clone repository
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF

# Load framework
. .\VBAF.LoadAll.ps1
```
```

### Your First Neural Network (2 minutes)
```powershell
# XOR problem data
$xorData = @(
    @{Input=@(0,0); Expected=0},
    @{Input=@(0,1); Expected=1},
    @{Input=@(1,0); Expected=1},
    @{Input=@(1,1); Expected=0}
)

# Create network: 2 inputs ? 3 hidden ? 1 output
$nn = New-VBAFNeuralNetwork -Architecture @(2, 3, 1) -LearningRate 0.1

# Train
$results = $nn.Train($xorData, 1000)

# Test
foreach ($sample in $xorData) {
    $prediction = $nn.Predict($sample.Input)
    Write-Host "Input: $($sample.Input) ? Output: $($prediction[0])"
}
```

### Your First Q-Learning Agent (2 minutes)
```powershell
# Create agent
$agent = New-VBAFAgent -Actions @("up", "down", "left", "right")

# Agent learns from experience
$agent.Learn($state, $action, $reward, $nextState)

# Agent chooses best action
$bestAction = $agent.GetBestAction($state)
```

### Open the Dashboards (1 minute)
```powershell
# Learning visualization
. .\VBAF.Visualization.Example-Dashboard.ps1

# Market simulation (4 companies competing)
. .\VBAF.Business.Dashboard-Demo.ps1

# Validation dashboard (XOR + grid world)
. .\VBAF.Core.Test-ValidationDashboard.ps1
```

---

## Framework Architecture

VBAF consists of four layers:

### Core (Neural Network Primitives)
- **33 modules** implementing neural networks from scratch
- Neurons, layers, activation functions (Sigmoid, ReLU, Tanh)
- Backpropagation algorithm
- Training loops with convergence tracking

### RL (Reinforcement Learning)
- Q-Learning with epsilon-greedy exploration
- Experience replay for stable learning
- Q-table for state-action values
- Epsilon decay scheduling

### Business (Multi-Agent Simulation)
- 4 company agents (Pharma, Wine, Banking, AI)
- Market environment with supply/demand economics
- Game theory interactions (Nash equilibrium, cooperation)
- Random economic events (recessions, breakthroughs)

### Visualization (Real-Time Dashboards)
- Learning curves (error decreasing, rewards increasing)
- Network structure visualization
- Multi-agent market dynamics
- 20-30 FPS real-time updates

---

## Why VBAF?

### The Accessibility Problem

**Current RL frameworks require:**
- Python expertise
- Complex installation (pip, conda, virtual environments)
- Deep learning libraries (TensorFlow/PyTorch)
- GPU setup for performance
- Weeks to months learning curve

**VBAF offers:**
- PowerShell (already installed on Windows)
- Zero installation (uses built-in .NET)
- Complete transparency (see every algorithm step)
- Immediate start (no setup time)
- Learn RL concepts in hours, not months

### The Educational Gap

**Existing tools:**
- TensorFlow: Black box, optimized for production
- PyTorch: Research-focused, complex API
- No framework designed for teaching RL

**VBAF fills this gap:**
- Code reads like a textbook
- Algorithms fully visible
- Real-time visualization of learning
- Business-relevant examples

---

## Case Studies

### Multi-Agent Market Simulation

Four companies compete over 20+ quarters:
- **Emergent behaviors:** Price coordination, market segmentation
- **Game theory:** Nash equilibrium without communication
- **Economic realism:** Supply/demand, random shocks
- **Observable learning:** Watch strategies evolve in real-time

### Generative RL: Castle Generation

Q-learning agent creates aesthetic compositions:
- 8 castle types (Gothic, FairyTale, Cathedral, Wizard, Palace, Oriental, Fortress, Ruins)
- Reward shaping for visual harmony
- Convergence from random to skilled in ~200 episodes

### XOR Problem

Classic neural network validation:
- Proves non-linear learning capability
- >95% accuracy after training
- Visual learning curve shows convergence

---

## Comparison: VBAF vs. Production Frameworks

| Aspect | VBAF | TensorFlow/PyTorch |
|--------|------|-------------------|
| **Primary Goal** | Education, accessibility | Production ML at scale |
| **Performance** | Modest (PowerShell interpreted) | Excellent (C++/CUDA) |
| **Learning Curve** | Hours (if know PowerShell) | Weeks to months |
| **Transparency** | Full algorithm visibility | Optimized black boxes |
| **Installation** | None (included with Windows) | Complex (Python, drivers, packages) |
| **Target User** | IT pros, business analysts, students | ML engineers, researchers |
| **Use Case** | Teaching, business automation | Research, production ML |

**VBAF is not competing with TensorFlow** - it's making RL accessible to a different audience.

---

## Documentation

- **[Getting Started](docs/GettingStarted.md)** - Installation and first steps
- **[Architecture](docs/Architecture.md)** - System design and components
- **[Theory](docs/Theory.md)** - Neural networks and RL algorithms explained
- **[API Reference](docs/API-Reference.md)** - Complete function and class documentation
- **[Tutorials](docs/tutorials/)** - Step-by-step guides
- **[Case Studies](docs/case-studies/)** - Real-world applications
- **[Research Paper](docs/papers/vbaf-main-paper.md)** - Academic paper (draft)

---

## Features

**Neural Networks:**
- Multi-layer perceptrons
- Backpropagation from scratch
- Multiple activation functions
- Customizable architectures

**Reinforcement Learning:**
- Q-Learning algorithm
- Experience replay
- Epsilon-greedy exploration
- Reward shaping utilities

**Multi-Agent Systems:**
- Company agents with RL brains
- Market environment simulation
- Economic modeling (supply/demand)
- Game theory interactions

**Visualization:**
- 3 real-time dashboards
- Learning curves
- Network structure display
- Market dynamics

**PowerShell Native:**
- No dependencies
- Uses built-in .NET libraries
- PowerShell 5.1 compatible
- WinForms for UI

---

## Requirements

- **Windows** 10 or 11
- **PowerShell** 5.1+ (included with Windows)
- **No additional dependencies**

---

## Installation

### Option 1: PowerShell Gallery
Install directly from PowerShell Gallery:

### Option 1: Clone Repository
```powershell
git clone https://github.com/JupyterPS/VBAF.git
cd VBAF
. .\VBAF.LoadAll.ps1
```
That's it! All functions are now available.

### Option 2: Clone Repository
Then choose your loader:
```powershell
# Enterprise Automation Engine (full - all pillars)
. .\VBAF.LoadAll.ps1

# Core Framework only (algorithms, ML, RL - no Enterprise pillars)
. .\VBAF.LoadCore.ps1
```
### Option 2: Download ZIP

1. Download ZIP from GitHub
2. Extract to desired location
3. Open PowerShell in that directory
4. Run: `. .\VBAF.LoadAll.ps1`

---

## Examples

See the `examples/` folder for complete working examples:

- **01-XOR-Network/** - Neural network solving XOR
- **02-Castle-Learning/** - Q-Learning for generative art
- **03-Market-Simulation/** - Multi-agent economics
- **04-Learning-Dashboard/** - Visualization demo
- **05-Validation-Dashboard/** - Framework validation
- **06-Custom-Agent/** - Build your own agent

---

## Academic Usage

### Citation

If you use VBAF in academic work, please cite:
```bibtex
@software{vbaf2025,
  author = {Henning},
  title = {VBAF: Visual Business Automation Framework for Reinforcement Learning Education},
  year = {2025},
  url = {https://github.com/JupyterPS/VBAF},
  note = {PowerShell-based RL framework emphasizing pedagogical transparency}
}
```

### Research Paper

Full academic paper available at: [docs/papers/vbaf-main-paper.md](docs/papers/vbaf-main-paper.md)

Topics covered:
- Framework architecture and design principles
- Neural network and Q-learning implementation details
- Multi-agent market simulation analysis
- Educational effectiveness evaluation
- Comparison to production ML frameworks

---

## Contributing

Contributions are welcome! See [Contributing Guide](docs/dev/contributing.md) for details.

**Areas for contribution:**
- New case studies and examples
- Documentation improvements
- Tutorial content
- Bug fixes and optimizations

---

## License

MIT License - See [LICENSE](LICENSE) for details.

Academic and commercial use permitted with attribution.

---

## Author

**Henning**  
Roskilde, Denmark

PowerShell automation specialist exploring AI/ML applications in business contexts.

---

## Acknowledgments

- PowerShell community for inspiration
- Reinforcement learning research community
- Microsoft for PowerShell platform

---

## Contact

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas

---

**"Making reinforcement learning accessible to those who automate businesses, not just those who optimize neural networks."**


