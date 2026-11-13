# Skills

Reusable agent skills by [tpluscode](https://github.com/tpluscode).

| Skill | Purpose |
| --- | --- |
| [node-cli-entrypoint](skills/node-cli-entrypoint/SKILL.md) | Bootstrap a Node.js CLI with a POSIX shell launcher that selects optional `tsx` or `ts-node` support, falling back to plain Node. |

Install with the skills CLI:

```sh
npx skills add tpluscode/skills --skill node-cli-entrypoint
```

Example request after installation:

> Use $node-cli-entrypoint to bootstrap a CLI that can load TypeScript configuration when tsx or ts-node is available.
