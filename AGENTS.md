# Capture the Flag — agent entrypoint

> STOP: agent guidance lives in `AI/AGENTS.md` — read and edit that file,
> not this one. `AI/` is gitignored and never committed; this file is only
> a boot pointer for fresh clones where `AI/` is absent.

If `AI/AGENTS.md` exists, follow it and ignore the rest of this file.

Bare-minimum boot (no `AI/` present):
- Lua 5.1, tabs, `luacheck .` is the only CI check.
- Use `core`, never `minetest`;
- Lua errors crash the server.
