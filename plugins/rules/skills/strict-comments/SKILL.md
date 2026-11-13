---
name: strict-comments
description: >
  Enforce strict comment rules on the current branch diff: comments only on
  public members, 3 lines max, and no references to anything outside the code
  (issues, tickets, external or design docs). Violations are fixed directly,
  restructuring code when needed instead of keeping long explanations.
---

# Strict Comments

This skill enforces three hard rules for comments on any PR or code change.
It scans the **current branch diff** and **directly fixes** every violation.
The rules are not judgment calls — a comment that breaks one of them is a
violation even if it looks useful.

## The three rules

1. **Only public members may have comments.** No comments on private members,
   and no inline comments inside logic blocks — function bodies, loops,
   conditionals, match/switch arms.
2. **Hard limit of 3 lines per comment.** If a comment needs more than 3
   lines, the code is not self-explanatory. Fix the code, don't keep the
   comment.
3. **Never reference anything outside the code.** No issues or tickets,
   external docs, design docs, roadmap notes, or review threads. The reader
   has no context for them — that material belongs in the commit message or
   PR description.

## Workflow

1. **Get the diff.** Find the base branch
   (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main` or
   `master`) and read the added/modified hunks with `git diff <base>...HEAD`.

2. **Find every comment in the diff.** Inline `#`, `//`, `/* */`, docstrings,
   JSDoc, KDoc, `///` and `//!` doc comments — every newly-added or modified
   comment. Ignore comments not touched by the diff.

3. **Check each comment against the three rules.** A comment must pass all
   three to stay.

4. **Fix violations.** Use the `Edit` tool; read each file before editing.
   How to fix depends on the rule broken:

   - **Rule 1 (private member / inline comment):** delete the comment. If it
     documents something a future reader genuinely needs, restructure so the
     explanation lands legally — hoist the private helper to a documented
     public function, or rename the function/variable/test so the name
     carries the intent. Never leave the comment in place.
   - **Rule 2 (over 3 lines):** first try trimming to ≤3 lines by dropping
     narration and keeping only the essential contract. If the excess
     content is real (units, invariants, edge cases that can't fit),
     restructure instead: split the member, improve names, or move detail to
     per-parameter/per-field docs where each stays within the limit.
   - **Rule 3 (external reference):** remove the reference. If the
     surrounding sentence still says something true about the code, keep the
     trimmed sentence; otherwise delete the whole comment. Suggest moving
     the removed context to the PR description in your final report.

5. **Report.** Print a per-file summary: `path:line` → rule broken + fix
   applied, then totals. List any context you removed under rule 3 so the
   user can paste it into the PR description.

## What the rules mean in practice

- **Public members** are the exported/visible API surface: public classes,
  functions, methods, fields, top-level constants, proto messages and fields.
  Private = language-private (`_name` in Dart/Python, `private` in
  Kotlin/Java/TS, unexported in Go, non-`pub` in Rust) or file/module-local
  helpers.
- **Class docs are not optional-empty.** A public class gets one concise
  summary of its responsibility (≤3 lines). No "key points" bullet scatter.
- **If the PR expanded a pre-existing one-line comment**, restore the
  original line rather than deleting it.
- **A comment restating the code breaks the spirit of rule 2** even at one
  line — the code was already clear, so the comment adds nothing. Delete it.
- **Test assertion messages are not comments — keep them.** They survive in
  failure output; they are not narration.

## Not comments — never touch

These look like comments but are read by tools. Preserve them unconditionally,
wherever they appear:

- License headers, copyright notices.
- Shebangs (`#!/usr/bin/env ...`).
- `# type: ignore`, `# noqa`, `# pragma: ...`, `# pylint: ...`.
- `// @ts-ignore`, `// @ts-expect-error`, `// eslint-disable-...`.
- `// biome-ignore`, `// prettier-ignore`, `// ignore:`, `// ignore_for_file:`.
- `// SAFETY:` on Rust `unsafe` blocks.
- Any directive a linter, type checker, formatter, or build tool reads.

## Constraints

- **Stay in the diff.** Only touch comments in added or modified hunks.
  Pre-existing comments are out of scope, even if they violate the rules.
- **Never modify non-comment lines** except when restructuring code to
  replace a deleted comment (rule 1/2 fixes) — and then change only what the
  restructure requires. No reformatting, no "while I'm here" fixes.
- **Skip pure-prose files.** `*.md`, `*.mdx`, files under `docs/**`, and
  similar are documents, not code comments.
- **Applies to every language alike**, test files included.

## Final report

End with a short verdict block:

```
strict-comments summary
  src/foo.py        3 deleted (rule 1), 1 trimmed (rule 2)
  src/bar.kt        1 restructured (rule 2), 2 cleaned (rule 3)
  ─────────────────────────────────────────────
  totals            7 violations fixed, 0 remaining

moved out of code — add to the PR description:
  src/bar.kt:42  removed "see #123 and the rollout design doc";
                 context: this flag gates the phased rollout
```
