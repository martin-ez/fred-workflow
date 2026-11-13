# FRED workflow

File, Refine, Execute, Decide: how work moves from an idea to merged code
through a tracker. The user makes the architecture and UX decisions; agents do
the rest.

## Statuses

- **Inbox**: filed, not yet triaged.
- **Needs decision**: waiting on the user. The open questions are on the issue,
  each with options and a recommendation.
- **Ready**: can be built without further conversation.
- **In progress**: one agent is building it.
- **In review**: pull request open, waiting on the user.
- **Done**: merged. **Dropped**: closed without doing it.

"Blocked" is a link between issues, not a status.

## Rules

1. Never settle a decision that belongs to the user (see below). If
   `decisions/` doesn't answer it, move the issue to Needs decision.
2. Otherwise, move the issue to Ready.
3. Execute only Ready issues with no open blockers. Moving an issue to In
   progress claims it; never take one that is already In progress.
4. File freely: any bug, gap or idea you notice outside the issue at hand goes
   to Inbox, instead of being fixed on the spot or forgotten. Filing never needs
   the user's permission; triage decides what is worth doing. Before you finish
   any task, file what you noticed along the way. Its source is `user` if the
   user asked for it, otherwise `agent` with "Found while working on #N".

## What the user decides

The outside of things: whatever someone else will come to depend on.

- **Architecture**: how data is stored and shaped, the contracts between
  parts (APIs, file formats, protocols), and new dependencies. How something
  works behind its contract is implementation.
- **UX**, when people use the product: what they can do, where in their
  journey they can do it, and what happens when they do. How it looks
  (colour, spacing, type) is UI.
- **Scope**: whether work the user didn't ask for is worth doing.

If unsure, ask what it would cost to change your mind next month. Migrating
data, breaking a contract or changing something users have learned is the
user's call. Everything else is yours: decide, mention it in the pull request
if it isn't obvious, and keep going.

## The four kinds of work

The user asks for these in plain words. There are no commands.

- **File**: capture work as Inbox issues, from one thing noticed mid-task to a
  whole plan brainstormed with the user.
- **Refine**: triage Inbox into Ready or Needs decision. Needs no user.
- **Execute**: take Ready issues to draft pull requests, then In review.
- **Decide**: walk the user through Needs decision, one question at a time,
  recommendation first. Write the answers on the issue, then move it on.

## Decisions

`decisions/` holds one file per subject, such as a kind of data or a part of
the product, named after the question it answers. Check it before asking the
user anything.

Record a decision only when the user makes it, it is a contract with the
people using the product or between its parts, and reversing it would mean
migrating data, breaking that contract or changing something users have
learned. Leave out open questions, temporary scope and anything a pending
experiment could still change; the tracker holds those. If part of an answer
isn't built yet, say so in one line that links the issue that will build it,
and delete the line in that issue's pull request.

If a record already covers the subject, extend it and add the issue to its
Decided in line instead of adding a file. If the new answer replaces an old
one, move the old one under Rejected; git keeps the history. Write the record
in the pull request that implements it, so merging approves it. If records
overlap or have gone stale, file an issue.

A record holds only while its Why does. When it no longer does, move the issue
to Needs decision and say what changed. If the user keeps the answer, rewrite
the Why and put the proposed change under Rejected.

```md
# <The question>
Decided in #N

**Applies when:** <the situation a future agent will be in>
**Answer:** <what was decided>
**Why:** <the reason, specific enough to tell when it no longer holds>
**Rejected:** <options turned down, and why> (optional)
```

## Lessons

Put what you learned where the next agent will run into it: a decision record,
a fix (file it), or beside the code.

## Setup

FRED stays out of the project's code: the only thing it adds to a project is
`decisions/`. The user's registry, `~/.claude/fred.md`, lists the projects that
use FRED and how each one's tracker works:

```md
# FRED

<rules for every project (optional)>

## <project repository or folder, e.g. github.com/me/app or ~/code/app>
Tracker: <which tracker, and where>
Statuses: <how each status is shown>
Source: <how the source is shown>
Blockers: <how a blocker is recorded>
Done: <how merging a pull request closes its issue>
<rules for this project (optional)>
```

A repository matches every clone of it, wherever it is, such as a cloud
session's; a folder matches only that folder and what's inside it.

To set a project up, ask the user which tracker to use, then check that
tracker's documentation for how best to do each of these, above all how
merging a pull request closes its issue, so that Done takes no extra step.
Write the answers into the project's section, and create what they need in the
tracker, such as labels or states.

Rules in the registry take precedence over this file, and a project's rules
over the user's rules for every project.
