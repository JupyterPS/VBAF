# Frequently Asked Questions

> 🚧 **Placeholder** — FAQ will grow as community questions come in.

## Why PowerShell 5.1?

VBAF is an **educational framework** — PS 5.1 is available on every Windows machine
with no install required. The goal is to teach ML concepts without a Python setup barrier.

## Why not PS Core (7+)?

PS 5.1 class semantics are more restrictive, which makes the implementation
challenges more explicit and educational. PS Core support is on the roadmap.

## Why do layers use hashtables instead of typed classes?

PS 5.1 typed arrays stored in ArrayList return **value copies** on index access.
Hashtables are always references — essential for weight mutations to persist
during backpropagation. See docs/Architecture.md for full explanation.

## Can I use VBAF for real ML work?

VBAF is primarily educational. For production ML use Python (scikit-learn, PyTorch).
VBAF's value is in **understanding** how these algorithms work from scratch.
