# 03 — Q-Learning Agent

## What You Will Learn

- The difference between supervised learning and reinforcement learning
- How Q-learning works with a Q-table
- How to train an agent that improves through experience

## Concept

Q-learning builds a table of Q-values: Q(state, action) = expected future reward.
The agent picks the action with the highest Q-value for the current state.
After each action it updates the Q-value using the Bellman equation.
```
Q(s,a) = Q(s,a) + alpha * (reward + gamma * max(Q(s')) - Q(s,a))
```

## Running the Example
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.RL.Example-CastleLearning.ps1"
```

## What to Watch

- Early episodes: agent takes random actions, reward is low
- Middle episodes: agent starts finding good paths, reward improves
- Late episodes: agent consistently takes optimal actions

## Q-table vs DQN

Q-learning with a table works well for small, discrete state spaces.
When the state space is large or continuous, the table becomes too big.
DQN replaces the table with a neural network — see Tutorial 12.

## Next Step

[04 — Multi-Agent Market](04-Multi-Agent-Market.md)
