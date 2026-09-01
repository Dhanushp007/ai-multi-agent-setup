# surface: both
# /docs — Generates documentation for the selected code.

Generate documentation for the selected code:
- Use the language's native format (JSDoc for JS/TS, docstrings for Python, XML docs for C#)
- Document: purpose, all parameters (type + description), return value, thrown errors/exceptions
- Add a brief usage example if the function is non-trivial
- Write from the caller's perspective — what does it do, not how
- Do not document obvious one-liners or self-evident property accessors
- Match the style and verbosity of any existing docs already in the file
