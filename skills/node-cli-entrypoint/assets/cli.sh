#!/usr/bin/env sh

# Resolve from the consuming project; see SKILL.md for global CLI installation.
entrypoint=$(node -e "console.log(require.resolve('__PACKAGE_NAME__/bin/index.js'))") || exit "$?"

if command -v tsx > /dev/null 2>&1
then
  exec node --import tsx --no-warnings "$entrypoint" "$@"
elif command -v ts-node > /dev/null 2>&1
then
  exec node --loader ts-node/esm/transpile-only --no-warnings "$entrypoint" "$@"
else
  exec node "$entrypoint" "$@"
fi
