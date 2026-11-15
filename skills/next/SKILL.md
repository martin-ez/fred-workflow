---
name: next
description: >
  Choose what to work on next in a FRED project: review the Ready issues with
  no open blockers, weigh them against the roadmap, and let the user pick one
  from a short list, best first. Use when the user asks what to work on, what's
  next or where to start, often at the start of a session.
argument-hint: "[area or milestone to focus on]"
---

# Next

Find the issues that can be started now, recommend the ones that move the
roadmap furthest, and let the user choose. Claim nothing until they do.

## Gather

1. **The project.** Its FRED settings are in your context when the session
   started in a registered project. When they aren't, as in a session started
   above several checkouts, run
   `CLAUDE_PROJECT_DIR=<checkout> sh "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" --registered-only`
   for each checkout and use the ones it prints settings for. If none does,
   say so and stop.
2. **The issues.** List every open issue with its status, its place on the
   roadmap and its open blockers, in as few calls as the tracker allows.
3. **The roadmap.** The order the project plans its work in: milestones, a
   project board, priority labels or a plan in the repository. Read their
   descriptions too; they often say what a stage is for and what it waits on.
4. **The candidates.** Ready issues with no open blockers, as the workflow's
   rule 3 says. If the user named a focus, such as an area or a milestone,
   keep to the candidates that fit it. Read each candidate's body and
   comments.

## Weigh

Recommend the candidate that does the most for the roadmap. Weigh:

- **Roadmap order.** Earlier stages first, and finishing a stage before
  starting the next. Work outside the roadmap ranks on what it unlocks.
- **What it unlocks**, judging the project as a whole and not only the links
  between issues: the issues waiting on it, above all Ready ones waiting on
  nothing else; what the user or agents could do that they can't now, such as
  checking their own work or previewing a branch; and what it opens up, such
  as a part of the product people could start using or a risk retired.
- **Whether it can be finished now.** What would stop it partway, such as a
  decision or review the project's rules keep for the user, a credential to
  ask for, or a service the session can't reach. Say so on the option rather
  than leaving it out.
- **Clashes.** Work that would change the same code as an issue In progress
  or In review ranks lower.

## Ask

Ask which issue to take in one AskUserQuestion question. Offer the best
candidates, up to four, best first, with "(Recommended)" after the first
label. For each option:

- **Label:** the issue number and a few words, such as `#11 Host the web app`.
- **Description:** one or two plain sentences: what will exist when it is
  done, then why now or what to weigh, such as what it unblocks or where it
  will stop for the user.
- **Preview:** a few short lines: its place on the roadmap, what it delivers,
  what it unblocks, what it needs from the user and its rough size.

The dialog may hide your message, so the question stands on its own: say how
many issues are Ready and unblocked and, in a few words, what holds up the
rest, such as "6 more Ready issues wait on #14".

With fewer than two candidates, fill the options with the other work waiting:
Refine when there are Inbox issues and Decide when issues Need decision, each
with its count. With nothing to offer at all, say so and stop.

## Start

When the user picks an issue, check that it is still Ready and unclaimed,
since another session may have taken it, then claim it by moving it to In
progress and Execute it under the workflow. When they pick Refine or Decide,
do that. When they answer in their own words, follow them.

## On GitHub

One REST call lists the open issues with their labels, milestone and native
blockers, where `blocked_by` counts open blockers only and `blocking` the open
issues it holds up. Keep `body` too when blockers are lines in it.

```sh
gh api 'repos/OWNER/REPO/issues?state=open&per_page=100' --paginate --jq '.[] | select(.pull_request | not) | {number, title, labels: [.labels[].name], milestone: .milestone.title, blocked_by: .issue_dependencies_summary.blocked_by, blocking: .issue_dependencies_summary.blocking}'
```

`gh api 'repos/OWNER/REPO/milestones?state=open'` lists the milestones with
their descriptions, and `gh api repos/OWNER/REPO/issues/N/dependencies/blocked_by`
names an issue's blockers.
