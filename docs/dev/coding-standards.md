# VBAF Coding Standards

> 🚧 **Placeholder** — full standards document coming soon.

## Key PS 5.1 rules (hard-won!)

1. **Layers as hashtables** in ArrayList — not typed class properties
2. **Direct element assignment**: \\.W[\] = value\ — persists in hashtable ✅
3. **Functions in class methods**: \& (Get-Command Func) -Param val\
4. **No -Verbose parameter** — reserved PS 5.1 common param, use -PrintEvery
5. **No foreach/switch on arrays** in class methods — use \or (\...)\ loops
6. **Comma-protect returns**: \eturn ,\\ — prevents pipeline unrolling
7. **No inline (if ...)** as argument values — pre-compute into a variable first
