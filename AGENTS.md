# Repository Guidelines

## Project Structure & Module Organization
- `src/index.js`: Main Cloudflare Worker entrypoint (API routes + SPA asset fallback).
- `public/`: Static frontend assets (`index.html`, `manifest.json`, `sw.js`, generated `output.css`).
- `scripts/`: Operational scripts for deployment checks, backups, CDN, load tests, and utilities.
- `schema.sql`: Base D1/SQLite schema (`users`, `lists`, `tasks`).
- `wrangler.toml`: Worker config, D1 binding, asset binding, and runtime vars.
- `.github/workflows/`: CI/CD and automation workflows.

## Build, Test, and Development Commands
- `npm run dev`: Start local Worker dev server via Wrangler.
- `npm run build`: Build CSS and dry-run Worker output into `dist/`.
- `npm run build:css`: Compile/minify Tailwind CSS from `src/input.css` to `public/output.css`.
- `npm run lint` / `npm run lint:fix`: Run ESLint checks and optional auto-fixes.
- `npm run format`: Format repository files with Prettier.
- `npm run test`, `npm run test:coverage`: Run Vitest tests and coverage.
- `npm run test:e2e`: Run Playwright end-to-end tests.
- `npm run deploy`: Deploy Worker to Cloudflare.

## Coding Style & Naming Conventions
- Use ESM JavaScript (`"type": "module"`) and keep code compatible with Node 18+.
- Follow existing style in `src/`: 2-space indentation, semicolons, `camelCase` for functions/variables, clear helper naming (`hashPIN`, `verifyJWT`).
- Keep API helpers small and composable (for example `json()`, `err()`, `auth()`).
- Run `npm run lint && npm run format` before opening a PR.

## Testing Guidelines
- Frameworks: Vitest (unit/integration) and Playwright (E2E).
- Place tests under `tests/unit`, `tests/integration`, and E2E specs under Playwright defaults.
- Name test files by behavior, e.g. `auth.login.test.js`, `lists.tasks.integration.test.js`.
- For API changes, add at least one success case and one auth/error case.

## Commit & Pull Request Guidelines
- Current history is minimal (`Initial commit`); use short imperative commit messages going forward.
- Recommended format: `type(scope): summary` (example: `feat(api): add task share revoke endpoint`).
- PRs should include:
  - What changed and why.
  - Test evidence (commands run and results).
  - Screenshots/video for UI changes.
  - Linked issue or task when applicable.

## Security & Configuration Tips
- Never commit secrets. Use `wrangler secret put <NAME>` for runtime secrets.
- Use `.env.example` as the source of required variables for local setup.
- Validate database changes locally before running remote D1 migrations.
