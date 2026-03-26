# Case Study: Castle Generation

## The Problem

Generating varied, believable castle layouts procedurally is hard.
Rule-based generators produce repetitive results.
The goal was a generator that learns what makes a good castle layout
by competing agents playing against each other.

## The VBAF Solution

Two competing Q-learning agents — Builder and Attacker.
Builder places walls, towers and gates to maximise defence score.
Attacker finds weaknesses to maximise breach score.
The agents play thousands of games, each improving against the other.

## Signals

Builder state: [wall coverage, tower count, gate exposure, symmetry score]
Attacker state: [breach attempts, weak points found, path length, coverage]

## Actions

Builder: Place wall / Place tower / Reinforce gate / Add moat
Attacker: Scout / Probe wall / Rush gate / Flank tower

## Results

After 500 episodes, the builder produces layouts that:
- No two layouts are identical
- All gates are defended by at least one tower
- Walls form continuous perimeters with no gaps
- The attacker cannot find a consistent breach path

## Run It
```powershell
. .\VBAF.LoadAll.ps1
& ".\VBAF.Art.CastleCompetition.ps1"
```
