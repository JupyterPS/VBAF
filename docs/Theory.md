# Theory — Reinforcement Learning in VBAF

## What is Reinforcement Learning?

Reinforcement learning (RL) is a type of machine learning where an agent
learns by interacting with an environment. Unlike supervised learning,
there are no labelled examples — the agent discovers good behaviour
through trial, error and reward signals.
```
Agent -> Action -> Environment -> Reward + Next State -> Agent
```

## Key Concepts

### State
A numerical representation of the current situation.
In VBAF, states are always 4 normalised values (0.0 to 1.0).
Example: [CPU load, memory free, error rate, latency]

### Action
A discrete choice the agent can make.
In VBAF, agents always choose from 4 actions (0, 1, 2, 3).
Example: 0=Monitor, 1=Warn, 2=Reserve, 3=Escalate

### Reward
A scalar feedback signal after each action.
VBAF uses a symmetric reward: +2 correct, -1/-2/-3 for wrong actions.
The agent maximises cumulative reward over time.

### Policy
The mapping from states to actions that the agent has learned.
A good policy takes the correct action for each situation.

## Q-Learning

Q-learning learns a Q-table: Q(state, action) = expected future reward.
Simple and effective for small, discrete state spaces.
```
Q(s,a) = Q(s,a) + alpha * (reward + gamma * max(Q(s')) - Q(s,a))
```

## Deep Q-Network (DQN)

DQN replaces the Q-table with a neural network.
This allows learning in continuous or large state spaces.

Key innovations:
- Experience replay: stores past transitions, samples randomly to break correlations
- Target network: a copy of the main network updated every N steps for stability
- Epsilon-greedy: starts exploring randomly, gradually exploits learned policy

## VBAF DQN Architecture

Every enterprise pillar uses:
- State size: 4 (normalised 0.0-1.0 signals)
- Action size: 4 (severity-ordered responses)
- Hidden layers: 24 -> 24 neurons
- Activation: sigmoid
- Optimizer: Adam
- Replay buffer: 10,000 transitions
- Batch size: 32
- Epsilon decay: 0.9995 per step
- Target sync: every 10 episodes

## The Distribution Formula

VBAF uses a proven training distribution of 15/40/30/15 across severity levels.
This guarantees positive improvement because:
- The majority class (40%) gives +10 reward/episode when the agent collapses to it
- The minority classes create strong gradient pressure away from the extremes
- The agent cannot achieve positive reward by always picking action 0 or 3
