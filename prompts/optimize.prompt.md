# surface: both
# /optimize — Optimizes selected code for performance or resource efficiency.

Optimize the selected code:
- Identify the specific bottleneck before suggesting changes
- Focus on algorithmic improvements first, then implementation-level tweaks
- Show before/after with a brief explanation of why it's faster/cheaper
- Estimate impact: high (significant difference at scale) | medium | low (micro-opt)
- Do not optimize code that isn't in a hot path without noting that caveat
- If profiling is needed to confirm the bottleneck, say so
