---
name: strict-pr
description: >
  Write pull request titles and descriptions that a reader without context can
  follow: a short plain title, a few sentences on what the change does and
  why, and a high-level Changes section. Use whenever opening a pull request,
  changing its title or description, or fixing an existing one.
---

# Strict PR

A pull request's title and description are for humans who likely don't know
the repository or the change. They say briefly what the change is about and
how it is done at a high level. The details are what the code is for.

## The shape

```md
<One to three sentences: what this change does and why, in plain words.>

## Changes
- <how it is done, at a high level, one line each>

Closes #12
```

## The rules

1. **Title:** at most 72 characters, in plain words, saying what changes. No
   issue numbers. Use a type prefix such as `feat:` only if the repository's
   titles already do.
2. **Opening:** one to three sentences on what the change does and why,
   readable by someone new to the repository. No internal jargon, codenames
   or unexplained abbreviations.
3. **`## Changes`:** a few one-line bullets on how it is done, at a high
   level. No file paths, lists of functions or classes, line-level detail, or
   a walk through the diff. Name something only when the reader needs it,
   such as a new command or setting.
4. **Nothing else:** no other sections, checklists, test plans, emoji or
   sign-offs, unless the user or the repository's pull request template
   explicitly asks for them. Lines that close an issue, such as `Closes #12`,
   are fine. The opening and Changes stay under 150 words.

## On GitHub

Open pull requests with a GitHub tool's `create_pull_request`, and change a
title or description with its `update_pull_request`. Where there is no such
tool, as in some cloud sessions, write the fields to a JSON file and send it
with `gh api repos/OWNER/REPO/pulls --method POST --input FILE`, or
`gh api repos/OWNER/REPO/pulls/N --method PATCH --input FILE`. A hook checks
the text there and blocks the call with the problems to fix. `gh pr create`,
and `gh pr edit` with a title or description, are blocked so that every pull
request is checked.

To fix an existing pull request, read it, rewrite its title and description to
these rules, and update it.
