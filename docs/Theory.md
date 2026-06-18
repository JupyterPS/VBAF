# Theory -- Reinforcement Learning in VBAF

This document explains the theoretical foundations behind every algorithm
in VBAF. Read it alongside the examples -- theory without code is abstract,
code without theory is a black box.

---

## What is Machine Learning?

Machine learning is the study of algorithms that improve through experience.
Three main paradigms:

Supervised learning:
  Learn from labelled examples (input -> correct output).
  Used in VBAF for regression, classification, clustering.
  Examples: predict house prices, classify emails, cluster customers.

Reinforcement learning:
  Learn from interaction with an environment (action -> reward).
  No labels -- the agent discovers good behaviour through trial and error.
  Used in VBAF for enterprise automation, market simulation, game agents.

Unsupervised learning:
  Find structure in unlabelled data.
  Used in VBAF for clustering (KMeans, DBSCAN) and autoencoders.

---

## Neural Networks

### The Perceptron (1958)

A single neuron computes a weighted sum of inputs and applies an activation:

  output = activation(w1*x1 + w2*x2 + ... + wn*xn + bias)

A single perceptron can only learn linearly separable functions.
Minsky and Papert proved in 1969 that XOR cannot be learned by a single neuron.
This result killed AI research funding for a decade -- the first AI winter.

### Hidden Layers

The solution: add a hidden layer between input and output.
Hidden neurons learn intermediate representations that make
non-linear problems linearly separable in a transformed space.

The Universal Approximation Theorem (Cybenko, 1989):
  A feedforward network with one hidden layer and enough neurons
  can approximate any continuous function to arbitrary accuracy.

XOR is the simplest proof: a [2,3,1] network solves it reliably.

### Backpropagation (Rumelhart, Hinton & Williams, 1986)

Backpropagation computes how much each weight contributed to the error,
then adjusts all weights simultaneously to reduce the error.

Forward pass:  input -> hidden -> output -> compute error
Backward pass: propagate error gradient back through each layer
Weight update:  w = w - learning_rate * gradient

The learning rate controls how large each update step is:
  Too high (0.5+): weights overshoot, training oscillates or diverges
  Too low (0.0001): training is stable but very slow
  Typical range: 0.001 to 0.1 depending on problem complexity

VBAF uses 0.5 for XOR (simple problem, fast convergence needed)
and 0.001 for enterprise DQN agents (complex, stability matters more).

### Activation Functions

Sigmoid: output = 1 / (1 + exp(-x))
  Output range: 0 to 1
  Used in VBAF for all neural networks
  Drawback: vanishing gradient in very deep networks

ReLU: output = max(0, x)
  Output range: 0 to infinity
  Faster training for deep networks
  Not used in VBAF PS 5.1 (numerical stability concerns)

---

## Supervised Learning

### Regression

Predict a continuous output value from input features.
VBAF implements: LinearRegression, RidgeRegression, LassoRegression,
DecisionTree (regression), RandomForest.

Key metric: R2 (coefficient of determination)
  R2 = 1.0: perfect prediction
  R2 = 0.0: no better than predicting the mean
  R2 < 0.0: worse than predicting the mean

Regularisation (Ridge/Lasso):
  Adds a penalty for large weights to prevent overfitting.
  Ridge: penalty = lambda * sum(w^2)   -- shrinks all weights
  Lasso: penalty = lambda * sum(|w|)   -- drives some weights to zero

### Classification

Predict a discrete class label from input features.
VBAF implements: LogisticRegression, GaussianNaiveBayes,
MultinomialNaiveBayes, DecisionTree (classification), RandomForest.

Key metric: Accuracy = correct predictions / total predictions
Also: precision, recall, F1 score for imbalanced datasets.

### The Bias-Variance Tradeoff

Bias: error from wrong assumptions (underfitting -- model too simple)
Variance: error from sensitivity to training data (overfitting -- model too complex)

Symptoms:
  High bias:     low training score AND low test score
  High variance: high training score BUT low test score

Fixes:
  High bias:     more features, more complex model, more epochs
  High variance: regularisation, more data, simpler model, cross-validation

### Data Leakage

Data leakage occurs when information from the test set influences training.
The most common mistake: fitting the scaler on ALL data before splitting.

Correct pattern (always):
  1. Split data into train and test FIRST
  2. Fit scaler on TRAIN only: scaler.FitTransform(Xtrain)
  3. Apply to test: scaler.Transform(Xtest)

VBAF's TransformerPipeline enforces this pattern automatically.

---

## Reinforcement Learning

### The RL Framework

An agent interacts with an environment in a loop:

  State(t) -> Agent -> Action(t) -> Environment -> Reward(t) + State(t+1)

State:   a numerical description of the current situation
Action:  a discrete choice the agent makes
Reward:  a scalar feedback signal (positive = good, negative = bad)
Policy:  the mapping from states to actions the agent has learned
Episode: one complete run from start to terminal state

The agent's goal: maximise cumulative reward over time.

### Q-Learning (Watkins, 1989/1992)

Q-learning maintains a table Q(state, action) = expected future reward.
The Bellman equation updates Q-values after each step:

  Q(s,a) = Q(s,a) + alpha * [r + gamma * max(Q(s',a')) - Q(s,a)]

Where:
  alpha  = learning rate (how fast to update)
  gamma  = discount factor (how much to value future rewards)
  r      = immediate reward
  s'     = next state
  max Q(s',a') = best possible future value from next state
  TD error = r + gamma * max(Q(s',a')) - Q(s,a) -- how wrong we were

Strengths:
  Simple, transparent, inspectable -- you can read the Q-table
  Guaranteed to converge under certain conditions

Weaknesses:
  Q-table grows with number of states -- impractical for large spaces
  Cannot generalise to unseen states

### Deep Q-Network -- DQN (Mnih et al., 2013/2015)

DQN replaces the Q-table with a neural network that approximates Q-values.
The network takes a state as input and outputs Q-values for all actions.

Key innovations over Q-learning:

Experience replay (Lin, 1992):
  Store past transitions (s, a, r, s') in a circular buffer.
  Sample random mini-batches for training.
  Why: consecutive steps are highly correlated -- random sampling breaks this.
  VBAF default buffer size: 10,000 transitions, batch size: 32.

Target network:
  Maintain a copy of the main network updated every N episodes.
  Use target network to compute Q(s',a') in the Bellman update.
  Why: without it, the learning target moves every step -- training diverges.
  VBAF default: sync every 10 episodes.

Epsilon-greedy exploration:
  With probability epsilon: choose random action (explore)
  With probability 1-epsilon: choose best known action (exploit)
  Epsilon starts at 1.0 and decays toward 0.01 over training.
  VBAF default decay: 0.9995 per step.

VBAF DQN architecture (every enterprise pillar):
  Input:   4 state signals (normalised 0.0 to 1.0)
  Hidden:  24 -> 24 neurons, sigmoid activation
  Output:  4 Q-values (one per action)
  Optimiser: Adam, learning rate 0.001

### Proximal Policy Optimisation -- PPO (Schulman et al., 2017)

PPO is a policy gradient method -- it directly optimises the policy
rather than learning Q-values first.

Key idea: clip the policy update to prevent large destabilising steps.
The clipping ratio ensures the new policy never strays too far from the old.

Advantage over DQN:
  More stable training on continuous action spaces
  Works well with shared actor-critic architecture

Used in VBAF for: Invoke-PPOTraining on CartPole and custom environments.

### Asynchronous Advantage Actor-Critic -- A3C (Mnih et al., 2016)

A3C runs multiple worker agents in parallel, each exploring independently.
Workers asynchronously update a shared global network.

Key idea: diversity of experience across workers replaces the replay buffer.
No memory needed -- workers provide natural decorrelation.

Actor:   learns the policy (which action to take)
Critic:  learns the value function (how good is this state)
Advantage: how much better was this action than the average? A = r + V(s') - V(s)

Used in VBAF for: Invoke-A3CTraining on CartPole and custom environments.

### Comparing the Three Algorithms

| Feature | Q-Learning | DQN | PPO / A3C |
|---------|-----------|-----|-----------|
| State space | Small discrete | Large/continuous | Large/continuous |
| Memory | Q-table | Replay buffer | None (A3C) |
| Transparency | Full (read table) | Low (neural weights) | Low |
| Stability | High | Medium (needs target net) | High |
| Speed | Fast | Medium | Fast (A3C parallel) |
| VBAF use | Castle Learning | Enterprise pillars | Research/comparison |

---

## Multi-Agent Reinforcement Learning

### The Challenge

In single-agent RL, the environment is stationary -- the same action
in the same state always produces the same expected reward.

In multi-agent RL, other agents are part of the environment.
As they learn, the environment changes. This is called non-stationarity.
The Q-table or neural network never fully converges because the target keeps moving.

### Emergent Behaviour

When multiple agents optimise their own rewards in a shared environment,
complex collective behaviours emerge without being programmed:

Price wars: agents undercut each other, reducing all profits
Tacit collusion: agents independently learn to avoid price wars
Innovation races: agents discover R&D beats price competition
Market segmentation: agents find niches to avoid direct competition

These are the same phenomena studied in game theory and economics:
Nash equilibrium, Cournot competition, prisoner's dilemma.
VBAF reproduces them through Q-learning alone.

### The Herfindahl-Hirschman Index

H = sum of (market_share^2) for all companies

H > 0.25: one company dominates (regulators investigate in reality)
H < 0.15: competitive market (evenly distributed shares)

VBAF computes H automatically in the market simulation annual report.

---

## The VBAF Distribution Formula

Every enterprise pillar uses the 15/40/30/15 severity distribution:

  15% of steps: severity 0 (normal conditions)
  40% of steps: severity 1 (elevated -- most common)
  30% of steps: severity 2 (high)
  15% of steps: severity 3 (critical)

Why this works:
  A random agent scores approximately: 0.15*2 + 0.40*(-1) + 0.30*(-2) + 0.15*(-3) = -1.0 per step
  A perfect agent scores: +2.0 per step
  The gap guarantees measurable improvement every training run.

The distribution is not uniform (which would give a random agent 0 expected reward)
and not extreme (which would make training too easy or too hard).
It was validated empirically across all 14 VBAF enterprise pillars.

---

## Theory References

Minsky, M. & Papert, S. (1969). Perceptrons. MIT Press.
Rumelhart, D., Hinton, G. & Williams, R. (1986). Learning representations by back-propagating errors. Nature.
Cybenko, G. (1989). Approximation by superpositions of a sigmoidal function. Mathematics of Control, Signals and Systems.
Watkins, C.J.C.H. (1989). Learning from Delayed Rewards. PhD thesis, Cambridge University.
Watkins, C. & Dayan, P. (1992). Q-learning. Machine Learning, 8(3-4), 279-292.
Lin, L-J. (1992). Self-improving reactive agents based on reinforcement learning, planning and teaching. Machine Learning.
Mnih, V. et al. (2013). Playing Atari with Deep Reinforcement Learning. arXiv:1312.5602.
Mnih, V. et al. (2015). Human-level control through deep reinforcement learning. Nature, 518, 529-533.
Mnih, V. et al. (2016). Asynchronous Methods for Deep Reinforcement Learning. ICML.
Schulman, J. et al. (2017). Proximal Policy Optimization Algorithms. arXiv:1707.06347.