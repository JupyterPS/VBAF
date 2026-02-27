C:\Users\henni# VBAF Architecture

> 🚧 **Placeholder** — full architecture document coming soon.

## Phase overview

| Phase | Modules | Status |
|---|---|---|
| Phase 1-2 | Core classes, RL foundations | ✅ Complete |
| Phase 3 | RL algorithms (DQN, PPO, A3C) | ✅ Complete |
| Phase 4 | Supervised ML | ✅ Complete |
| Phase 5 | Data pipeline | ✅ Complete |
| Phase 6 | Deep learning (CNN, RNN, Autoencoder) | ✅ Complete |
| Phase 7 | Production (MLOps, AutoML, Explainability) | ✅ Complete |
| Phase 8 | Transfer Learning, benchmarks | 🚧 In progress |

## Key design decision: PS 5.1 reference semantics

Layers are stored as **hashtables in ArrayLists** — not typed class properties.
This guarantees reference semantics so weight mutations persist during backprop.
See [Theory.md](Theory.md) for details.

