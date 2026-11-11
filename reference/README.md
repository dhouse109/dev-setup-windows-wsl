# reference/

A read-only copy of what this bundle forks from. Nothing here runs, gets linted, or gets edited.

| Folder | Source | Tag | Commit | Copied |
|---|---|---|---|---|
| `dev-setup-chromebook/` | [dhouse109/dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) | `v101` | `68113ff633e19005707394b375f25dd505cfccee` (merge of `release/v101`, 2026-11-09) | 2026-11-11 |

What the copy holds, byte for byte from the tag (extracted with `git archive v101`):

- the four scripts: `dev-setup-chromebook.sh`, `dev-test-chromebook.sh`, `dev-init-chromebook.sh`,
  `dev-demo-chromebook.sh`
- `CHANGELOG.md`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `LICENSE`
- `docs/`, all of it, including `docs/plans/`

Left out: the Chromebook repo's `tests/`, `.github/`, `.gitignore` and `.gitleaks.toml`. This repo has
its own CI, `.gitignore` and `.gitleaks.toml`, adapted from those.

`dev-setup-chromebook/AGENTS.md` and `CLAUDE.md` are the **Chromebook repo's** rules. A coding agent that
loads them while reading files in this folder should take them as describing that repo, not this one;
this repo's rules are in the top-level `AGENTS.md`.

## Rules

- **Never edit anything in this folder.** It is a snapshot of a published Chromebook release, not
  working code. Don't run the scripts either (their host guard stops them anywhere but ChromeOS, and
  `DEV_BUNDLE_ANY_HOST` is never set to get past it).
- **Refresh only by replacing it wholesale** with a newer Chromebook tag, in a commit of its own:
  delete `dev-setup-chromebook/`, extract the same file list from the new tag with `git archive`, and
  update the table above (tag, commit SHA, copy date).
