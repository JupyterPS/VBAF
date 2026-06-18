# Example 02: Castle Learning

A Q-learning agent learns to generate varied castle sequences through
trial and error -- no strategy is programmed in. The agent discovers
on its own that variety is rewarded and repetition is penalised.

## Why This Example?

Example 01 (XOR) had one correct answer. This is different.
This is an optimisation problem -- many sequences are valid, but some
are better than others according to a reward function.

This is closer to real-world RL: no ground truth, just feedback.

## What The Agent Learns

The agent chooses castle types one at a time from 8 options:
  Gothic, FairyTale, Fortress, Palace, Wizard, Cathedral, Oriental, Ruins

Reward signal:
  +2 for choosing a castle type different from the previous one
  -1 for repeating the same type
  + visual balance and engagement scores (simulated)

Over 100 episodes the agent learns:
  - Repetition is bad -- avoid it
  - Variety is good -- mix the types
  - Some transitions score better than others on average

## Exploration vs Exploitation

This is the central tension in all reinforcement learning.

  Epsilon = 1.0  -- agent acts randomly (pure exploration)
  Epsilon = 0.5  -- half random, half learned
  Epsilon = 0.01 -- agent mostly uses what it learned (exploitation)

Epsilon decays automatically during training. Watch it in the output.
Too fast: agent stops exploring before finding good strategies.
Too slow: agent wastes time on random actions it no longer needs.

## The Q-Table

Q-learning stores knowledge in a table: one row per (state, action) pair.
State = the last few castle types chosen.
Action = the next castle type to choose.
Value = expected total reward from this choice.

After training you can READ the Q-table and understand exactly what
the agent learned. This is the key advantage over DQN -- full transparency.

## What To Watch While It Runs

  Episode 1:   Q-table ~0 entries, epsilon 1.0, rewards random
  Episode 50:  Q-table growing, epsilon decaying, rewards improving
  Episode 100: Q-table stable, epsilon near 0.01, agent exploiting

If recent average reward > overall average -- the agent improved.
That is the confirmation that Q-learning is working.

## Run It

```powershell
cd "C:\Users\henni\OneDrive\WindowsPowerShell\examples\02-Castle-Learning"
. .\Run-Example-02.ps1
```

## Expected Output

Episode   1 | Reward:   1.85 | Epsilon: 0.990 | Exploit:  1.0% | Q-Table:   2 entries

Episode  10 | Reward:   2.43 | Epsilon: 0.904 | Exploit:  9.6% | Q-Table:  14 entries

Episode  50 | Reward:   3.12 | Epsilon: 0.605 | Exploit: 39.5% | Q-Table:  38 entries

Episode 100 | Reward:   3.87 | Epsilon: 0.010 | Exploit: 99.0% | Q-Table:  51 entries
Agent IMPROVED -- recent rewards higher than overall average!

Q-learning successfully shifted from exploration to exploitation.

## What To Try Next

1. Increase episodes to 500 -- watch Q-table grow and epsilon reach 0.01
2. Change stepsPerEpisode to 20 -- more interactions per episode
3. Print the full Q-table directly: $agent.QTable | Format-Table
4. Compare with DQN on the same problem -- does a neural network learn faster?
5. Move on to examples\03-Market-Simulation\ -- multi-agent competition

## Key Concepts

- Q-learning (Watkins, 1989/1992)
- Epsilon-greedy exploration schedule
- Reward shaping -- designing the feedback signal
- Q-table transparency vs neural network opacity

## Files

- `Run-Example-02.ps1` -- run this to start the example
- `VBAF.RL.Example-CastleLearning.ps1` -- full example with educational comments
- Source: `..\..\VBAF.RL.QLearningAgent.ps1` -- Q-learning agent class
