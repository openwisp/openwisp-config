# AGENTS.md

## Project Overview

`openwisp-config` is the OpenWrt configuration agent that connects devices to OpenWISP Controller.

Core code lives in `openwisp-config/`:

- `files/` contains Lua code, shell scripts, UCI defaults, and runtime files installed on OpenWrt.
- `tests/` contains Lua and integration tests.
- `openwisp-config/Makefile`, `runbuild`, `runtests`, `qa-format`, and `run-qa-checks` support package build, test, and QA workflows.
- `docs/` is incorporated into the unified, versioned OpenWISP documentation built by `openwisp-docs`, not a standalone site; use `docs/user/` for end users and `docs/developer/` for contributors and developers of extensions, downstream, or derivative apps.
- `build/` contains the OpenWrt build workspace; `downloads/` contains package artifacts.

## Source of Truth

- Use `README.rst` and `docs/` for setup, package usage, and development workflows.
- Use `.github/workflows/ci.yml`, `.luacheckrc`, and package metadata for CI-tested build, QA, and test commands.
- Use GitHub issue/PR templates when asked to open issues or PRs.

If instructions conflict, repository config and CI workflows win first, docs next, and this file is supplemental.

## Contributing Guidelines

- Before editing, inspect the relevant implementation, tests, documentation, and configuration. Follow existing repository patterns and do not invent behavior or requirements.
- Keep each contribution focused and change only the lines necessary for its goal. Do not include unrelated refactors, formatting churn, or generated and dependency-file changes unless explicitly required.
- Add or update focused Lua tests for changes to existing Lua behavior. Use test-driven development when the scope is very clear, such as Lua bug fixes or narrowly scoped changes. For new Lua features, tests may be added after implementation, but confirm they fail when key feature code is removed. When a test failure does not clearly state the expected outcome that was not met, add an explicit assertion message. Validate shell and package changes with the relevant existing build and QA checks; do not add shell tests or a shell test harness unless explicitly required.
- Run `./qa-format` after each change.
- Run the relevant targeted tests, builds, and documented QA checks, including `./run-qa-checks` when provided. Do not claim a change is complete when verification fails; report the failure or blocker.
- When requirements, intended behavior, or an unexpected failure are unclear, stop and seek clarification instead of making speculative changes.
- When starting work on a new issue, create a new branch from `master`. Use `issues/<issue-number>-<short-title>` for issue work; otherwise, use a short, descriptive branch name.
- Commit messages must be descriptive and use past tense. Past tense is a writing guideline that agents and contributors must follow; it is not checked automatically. For issue work, use an allowed prefix and a capitalized, past-tense subject ending with `#<issue-number>`, for example `[fix] Fixed perennial "modified" state #213`. Repeat the issue reference in the body with `Fixes`, `Closes`, `Resolves`, or `Related to` as appropriate. After creating a commit, use `openwisp-commit --check` to validate the current `HEAD`; it cannot validate a proposed message. Use `openwisp-commit --check --rev-range <range>` for an existing commit range, and `cz -n cz_openwisp info` to view allowed prefixes and message structure.
- Add an explanatory commit body only for substantial changes, new features, or non-obvious bug fixes. The releaser automatically publishes the subject of `[feature]`, `[change]`, `[change!]`, `[deps]`, and `[fix]` commits, including scoped variants, in the changelog. Write those subjects in clear, user-friendly language suitable for release notes.
- Send new commits in response to review feedback instead of amending existing commits.

## Development Rules

- Preserve UCI configuration compatibility, package file paths, service behavior, upgrade behavior, and Controller API contracts unless explicitly required.
- Edit package sources under `openwisp-config/files/`; regenerate `build/` and `downloads/` instead of editing their contents directly.
- Be careful with Lua code, shell scripts, init scripts, network state, retry logic, registration, and generated configuration.
- Avoid unnecessary blank lines inside Lua functions and shell blocks.
- Prefer short, precise names that rely on their nearest meaningful scope. Do not repeat a feature, domain object, or namespace already named by the containing module, class, or function. For example, prefer `EstimatedLocation.refresh()` over `EstimatedLocation.refresh_estimated_location()`. Repeat that context only when the name is used outside that scope or is needed to distinguish genuinely different concepts. When a concise name cannot express a necessary distinction, use a concise docstring to describe it rather than encoding it in an excessively long name.
- Before adding a comment or docstring, ask whether it conveys information a reader cannot reasonably infer from clear code, names, and surrounding scope. Add a concise comment when it explains a non-obvious reason, constraint, compatibility or security requirement, side effect, or unavoidable complexity. In opaque syntax or domain-specific code, especially shell scripts, a comment may also explain what the code does. Do not add comments that merely restate adjacent code one-to-one.
- Update docs when behavior, settings, package options, setup steps, or supported OpenWrt versions change, including when a documented feature's behavior changes or a new user-facing feature is added.
- Review documentation examples and references when behavior changes.
- Preserve public documentation anchors, URLs, include directives, and versioned links unless explicitly required.

## Security Rules

- Watch for command injection, unsafe shell expansion, insecure TLS handling, leaked credentials, unsafe file permissions, and broken registration/auth flows.
- Preserve validation and safe handling around Controller URLs, shared secrets, certificates, UCI values, downloaded configs, and shell commands.
- Prevent secret disclosure, unsafe deployment instructions, stale security guidance, and insecure links.

## Troubleshooting

- If documentation and CI commands differ, use CI for verification and report the exact documentation path, CI workflow path, and differing commands. Do not change the documentation until the user explicitly chooses one of these actions: update the named documentation file in the current change because the divergence was caused by that change, or leave it unchanged for a separate follow-up. Never decide that scope distinction independently.
