# Agents

## Intake Agent
- **Trigger**: Push to `/workflows/*/scripts/*` or manual request via GitHub issue.
- **Action**:
  1. Parse scripts and `metadata.yaml` (if present) to extract:
     - Purpose
     - Inputs/outputs
     - Dependencies (modules, Python packages)
     - HPC assumptions
     - EC-Earth/NEMO versions
  2. Generate:
     - `docs/_workflows/<name>.md` using Jinja2 template.
     - `tests/<name>_smoke.sh` for basic validation.
     - Draft PR with generated files.
- **Engine**: Antigravity CLI (agy) or local LLM.
- **Safety**: Level 1 (docs-only; no code execution).
- **Rate Limit**: Max 3 open PRs/day.

## Validation Agent
- **Trigger**: PR opened, weekly schedule, or manual request.
- **Action**:
  1. Run `lint.sh` (ShellCheck) on scripts.
  2. Compare `metadata.yaml` dependencies against `infrastructure/mn5.yaml`.
  3. Run smoke tests (if available).
  4. Add PR comment with warnings (e.g., "netcdf/4.7 is deprecated").
- **Engine**: Static analysis + Antigravity CLI (agy).
- **Safety**: Level 1 (read-only; no modifications).

## Librarian Agent
- **Trigger**: Weekly schedule or PR merge to `main`.
- **Action**:
  1. Regenerate `WORKFLOWS.md` from all `metadata.yaml`.
  2. Validate internal links in docs (`mkdocs serve --strict`).
  3. Suggest doc improvements via Antigravity CLI (Level 2 review).
- **Engine**: Antigravity CLI (agy).
- **Safety**: Level 1 (auto-generated changes are PR-only).