# AGENTS.md

## Project Overview

`openwisp-config` is the OpenWrt configuration agent that connects devices to OpenWISP Controller.

Core code lives in `openwisp-config/`:

- `files/` contains Lua code, shell scripts, UCI defaults, and runtime files installed on OpenWrt.
- `tests/` contains Lua and integration tests.
- `Makefile`, `runbuild`, `runtests`, `qa-format`, and `run-qa-checks` support package build, test, and QA workflows.

## Source of Truth

- Use `README.rst` and `docs/` for setup, package usage, and development workflows.
- Use `.github/workflows/ci.yml`, `.luacheckrc`, and package metadata for CI-tested build, QA, and test commands.
- Use GitHub issue/PR templates when asked to open issues or PRs.

If instructions conflict, repository config and CI workflows win first, docs next, and this file is supplemental.

## Development Notes

- Keep changes focused. Avoid unrelated refactors and formatting churn.
- Preserve UCI configuration compatibility, package file paths, service behavior, upgrade behavior, and Controller API contracts unless explicitly required.
- Be careful with Lua code, shell scripts, init scripts, network state, retry logic, registration, and generated configuration.
- Avoid unnecessary blank lines inside Lua functions and shell blocks.
- Update docs when behavior, settings, package options, setup steps, or supported OpenWrt versions change.

## Testing and QA

- Add or update tests for every behavior change.
- For bug fixes, write the regression test first, run it against the unfixed code, confirm it fails for the expected reason, then implement the fix.
- Use targeted tests while iterating, then run the documented full build/test command before considering the change complete.
- Run `./qa-format` and `./run-qa-checks` when present. Treat failures as blocking unless confirmed unrelated and reported.

## Security Notes

- Watch for command injection, unsafe shell expansion, insecure TLS handling, leaked credentials, unsafe file permissions, and broken registration/auth flows.
- Preserve validation and safe handling around Controller URLs, shared secrets, certificates, UCI values, downloaded configs, and shell commands.
- Write comments only when they explain why code is shaped a certain way. Put comments before the relevant block instead of scattering them inside it.

## Troubleshooting

- If setup, QA, builds, or tests fail, check docs first, then compare with CI. If commands diverge, follow CI.
