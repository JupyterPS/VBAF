# Course Outline: ML with VBAF
## Course: Enterprise Machine Learning in PowerShell
Duration: 4 weeks (2 sessions per week, 2 hours each)
Level: IT professionals with PowerShell experience
Prerequisites: Basic PowerShell scripting (variables, loops, functions)

---

## Learning Objectives

By the end of this course, students will be able to:
- Train and evaluate supervised learning models on real datasets
- Build and tune a DQN reinforcement learning agent
- Design a custom enterprise automation pillar for their own domain
- Read and interpret learning curves, Q-tables and evaluation metrics
- Explain the theory behind each algorithm they use

---

## Week 1: Neural Networks and Supervised Learning

### Session 1: Your First Neural Network (2 hours)

Theory (45 min):
- What is machine learning? Supervised vs reinforcement learning
- Neural network concepts: layers, weights, activation functions
- Why XOR requires a hidden layer (Minsky & Papert 1969)
- The Universal Approximation Theorem (Cybenko 1989)

Hands-on (75 min):
- Load VBAF: `. .\VBAF.LoadAll.ps1`
- Run Example 01: `examples\01-XOR-Network\Run-Example-01.ps1`
- Tutorial 01: Your First Neural Network
- Tutorial 02: First Classifier
- Experiment: change architecture from [2,3,1] to [2,2,1] -- does it still solve XOR?

Key concepts: backpropagation, learning rate, convergence, random initialisation

---

### Session 2: Regression and Clustering (2 hours)

Theory (45 min):
- Classification vs regression vs clustering -- when to use each
- Overfitting and the bias-variance tradeoff
- Feature scaling -- why it matters for Ridge and distance-based models

Hands-on (75 min):
- Tutorial 06: First Regression Model (HousePrice dataset)
- Tutorial 07: KMeans Clustering
- Tutorial 08: Load Your Own CSV Data
- Lab: compare LinearRegression vs RidgeRegression on the same dataset

Key concepts: R2, RMSE, regularisation, StandardScaler, train/test split

---

## Week 2: The ML Pipeline

### Session 3: Feature Engineering (2 hours)

Theory (45 min):
- Why raw data rarely works: missing values, outliers, scale differences
- Imputation strategies: median vs mean vs zero
- Polynomial features and interaction terms

Hands-on (75 min):
- Tutorial 09: Feature Engineering Impact
- Use MissingValueImputer, OutlierDetector, PolynomialFeatures
- Measure R2 before and after each preprocessing step
- Lab: take a messy dataset, clean it, and compare model performance

Key concepts: data leakage, FitTransform vs Transform, pipeline order

---

### Session 4: Model Selection (2 hours)

Theory (45 min):
- Cross-validation: why a single train/test split is unreliable
- Hyperparameter tuning: grid search vs random search vs Bayesian
- AutoML: when to use it and what it cannot do

Hands-on (75 min):
- Tutorial 10: Model Comparison with cross-validation
- Tutorial 11: Correct Pipeline Pattern (avoiding data leakage)
- Run Invoke-VBAFAutoML on HousePrice dataset
- Lab: tune RidgeRegression lambda using Invoke-VBAFRandomSearch

Key concepts: k-fold CV, overfitting, hyperparameter space, Bayesian optimisation

---

## Week 3: Reinforcement Learning

### Session 5: Q-Learning (2 hours)

Theory (45 min):
- What is reinforcement learning? Agent, environment, reward cycle
- The Q-learning update rule (Bellman equation)
- Exploration vs exploitation -- the epsilon-greedy tradeoff
- When Q-tables work and when they fail

Hands-on (75 min):
- Run Example 02: `examples\02-Castle-Learning\Run-Example-02.ps1`
- Tutorial 03: Q-Learning Agent
- Inspect the Q-table: `$agent.GetQValues("Gothic|Fortress")`
- Experiment: increase episodes to 500 -- watch epsilon reach 0.01

Key concepts: Q-table, Bellman equation, epsilon decay, state representation

---

### Session 6: Deep Q-Networks (2 hours)

Theory (45 min):
- Why DQN improves on Q-learning: neural network generalisation
- Experience replay: breaking temporal correlations
- Target network: stabilising the learning target
- The DQN architecture used in VBAF (4->24->24->4)

Hands-on (75 min):
- Tutorial 12: Your First DQN Agent
- Run Example 05: `examples\05-Validation-Dashboard\Run-Example-05.ps1`
- Train DQN on CartPole: `Invoke-DQNTraining -Episodes 100 -PrintEvery 10`
- Compare DQN vs Q-learning on the same problem

Key concepts: neural network Q-function, replay buffer, target sync, epsilon schedule

---

## Week 4: Enterprise Automation

### Session 7: Enterprise Pillars (2 hours)

Theory (45 min):
- VBAF enterprise architecture: 4 layers, 14 pillars, one AutoPilot
- The standard pillar pattern: 4 states, 4 actions, 15/40/30/15 distribution
- Reading improvement percentages: what counts as success?
- SimMode vs real Windows data: same agent, different data source

Hands-on (75 min):
- Run Example 03: `examples\03-Market-Simulation\Run-Example-03.ps1`
- Run AutoPilot: `Invoke-VBAFAutoPilotTraining -Episodes 100 -SimMode`
- Run 3 individual pillars and compare improvement percentages
- Discuss: which pillar would be most useful in your organisation?

Key concepts: enterprise environment interface, DQNConfig, SimMode, improvement %

---

### Session 8: Build Your Own Pillar (2 hours)

Theory (30 min):
- Choosing state signals: what data is available via WMI, Get-WinEvent, Get-Counter?
- Designing the reward function: +2/-1/-2/-3 and why it works
- The 15/40/30/15 distribution: math explanation
- How to replace _Sample() with real Windows data

Hands-on (90 min):
- Run Example 06: `examples\06-Custom-Agent\Run-Example-06.ps1`
- Tutorial 13: Custom Enterprise Pillar (NetworkTrafficManager)
- Final project: each student designs and trains a pillar for their own domain
- Present results: baseline vs trained reward, improvement %, lessons learned

Key concepts: environment design, reward shaping, real data integration, GitHub PR

---

## Assessment

| Component | Weight | Description |
|-----------|--------|-------------|
| Weekly labs | 40% | Hands-on exercises each session |
| Mid-course quiz | 20% | Questions from exam-questions.md (weeks 1-2) |
| Final project | 40% | Custom enterprise pillar with written justification |

Final project requirements:
- Working PowerShell pillar file
- Baseline vs trained reward comparison
- Written explanation of state signals, actions and reward design
- Reflection on what worked and what did not

---

## Resources

- `examples\` -- 6 runnable examples covering the full learning path
- `tutorials\` -- 13 step-by-step tutorials
- `docs\Theory.md` -- reinforcement learning theory reference
- `docs\API-Reference.md` -- complete function reference
- `VBAF.CheatSheet.md` -- one-page quick reference
- `docs\teaching\exam-questions.md` -- 34 assessment questions with difficulty levels

---

## Instructor Notes

- Always run `. .\VBAF.LoadAll.ps1` at the start of every session
- ISE works for all console examples; WinForms dashboards require standalone console
- LF/CRLF warnings from Git are always safe to ignore
- If students get "Unable to find type" errors -- the fix is always LoadAll first
- The repair list pattern: note bugs during sessions, fix in batch after class