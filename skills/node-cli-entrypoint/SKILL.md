---
name: node-cli-entrypoint
description: Bootstrap or adapt Node.js CLI packages with a POSIX shell entrypoint that selects tsx, ts-node, or plain Node at runtime. Use for CLIs that optionally load user TypeScript configuration or plugins without requiring a TypeScript loader for JavaScript-only use.
---

# Node CLI Entrypoint

Use a thin shell launcher to select Node runtime flags before loading the CLI. Keep argument parsing and application behavior in JavaScript. This follows the pattern in `packages/cli/bin/kopflos.sh` in the `zazuko/kopflos` repository.

## Bootstrap the package

Inspect the target package's name, module format, supported Node versions, build output, `bin`, `files`, and `exports`. Reuse existing CLI and build tooling. For a new project, infer the command and package names from the request or repository context.

Copy [assets/cli.sh](assets/cli.sh) to `bin/<command>.sh`, replace `__PACKAGE_NAME__` with the real package name (including its scope), and make it executable. The template resolves `<package-name>/bin/index.js`; adjust that subpath for another layout.

Create a minimal JavaScript entrypoint, for example in an ESM package:

```js
#!/usr/bin/env node
import '../index.js'
```

Point it at the actual built application module. If the package compiles TypeScript, emit the referenced JavaScript before packing. Plain Node must be able to start the CLI without either loader installed; loaders support TypeScript loaded at runtime, such as user configuration and plugins.

Wire the manifest, adapting this fragment rather than replacing existing fields:

```json
{
  "type": "module",
  "bin": { "my-cli": "./bin/my-cli.sh" },
  "files": ["bin", "index.js", "lib"],
  "scripts": {
    "build": "tsc",
    "prepack": "npm run build"
  }
}
```

Include all runtime files, not just this example's paths. Preserve CommonJS packages' module format and use `require()` in their JavaScript entrypoint. Do not add a compiler or build hook to projects that ship JavaScript directly.

## Preserve launcher behavior

- Resolve the JavaScript entrypoint before choosing a loader. Stop with a useful error if resolution fails; never launch Node with an empty script path.
- Prefer `tsx` via `node --import tsx`; otherwise use `ts-node` via `node --loader ts-node/esm/transpile-only`; otherwise use plain `node`.
- Use `exec` in every branch so exit status and signals reach Node. Quote the script path and forward arguments exactly with `"$@"`.
- Keep POSIX `sh` compatibility; avoid Bash-only syntax and shell interpolation of user arguments.
- The original loader branches suppress Node warnings with `--no-warnings`; the template preserves this. Omit it when warnings should remain visible.

Keep loaders optional unless the user requests a mandatory dependency. The `ts-node` branch transpiles without type checking; use a separate type-check command when needed.

## Check resolution assumptions

The template deliberately preserves `command -v` loader detection. An executable on `PATH` does **not** guarantee Node can import that module. Validate imports in the intended consumer environment; when needed, adapt detection to probe Node's actual module resolution. Do not retry the application with another runtime after it starts and fails, because it may already have performed side effects.

`node -e` resolves the package entrypoint from the caller's working directory. This fits a CLI installed in the consuming project, including package-manager execution there. For a globally installed command invoked in an unrelated directory, resolve the entrypoint relative to the installed launcher, accounting for package-manager symlinks, and test that scenario explicitly.

If `exports` restricts the package, expose the entrypoint subpath or choose package-relative resolution. For example, merge `"./bin/index.js": "./bin/index.js"` into the existing exports map while preserving other exports.

Check supported Node versions against the runtime flags and selected loader versions. A POSIX launcher requires a shell; if native Windows support is required, choose a portable launcher rather than assuming npm's command shim supplies `sh`.

## Verify the generated CLI

Use an isolated consumer project or existing CLI integration tests. Check observable behavior:

- With neither loader available, JavaScript CLI startup succeeds.
- With `tsx` available, it is selected; with only `ts-node` available, that loader is selected. With both available, `tsx` wins. Load an actual TypeScript config or plugin with each loader.
- Arguments containing spaces, empty strings, or shell metacharacters arrive unchanged. Nonzero exit codes propagate, and a long-running command receives termination signals.
- A packed installation includes the executable wrapper and built entrypoint. Run the installed command from its intended working directory; test unrelated directories if global use is supported.

Use a controlled `PATH` for branch tests so global tools cannot accidentally select a loader. Stub Node only to inspect arguments and runtime selection; verify real loader imports separately. 
