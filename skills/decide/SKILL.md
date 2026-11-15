---
name: decide
description: >
  Work through the Inbox and Needs decision issues with the user, starting
  with those that unlock the most: rank them cheaply, sweep a batch of four
  where each can be decided now, skipped or archived, then refine the chosen
  ones and ask their open questions. Use when the user asks to triage, refine
  or decide issues, or to go through the inbox.
argument-hint: "[batch size] [area or milestone to focus on]"
---

# Decide

Turn the issues waiting on refinement or on the user into Ready work, in the
order that unlocks the most, without making the user read the whole backlog.
Spend effort on an issue only once the user chooses to decide it.

## Rank

1. **The project.** Its FRED settings are in your context when the session
   started in a registered project. When they aren't, as in a session started
   above several checkouts, run
   `CLAUDE_PROJECT_DIR=<checkout> sh "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" --registered-only`
   for each checkout and use the ones it prints settings for. If none does,
   say so and stop.
2. **The candidates.** Every open issue in Inbox or Needs decision. If the
   user named a focus, such as an area or a milestone, keep to the ones that
   fit it. Leave out issues already handled or skipped in this session.
3. **The order.** Rank by what deciding the issue unlocks: the issue itself
   becoming Ready, and the open issues waiting on it, above all Ready issues
   waiting on nothing else. Work in an earlier stage of the roadmap
   (milestones, a project board, priority labels) counts more than work in a
   later one. Use only what the issue list gives, such as titles, statuses,
   milestones and blocker counts; look further only to break ties near the
   top. Don't read issue bodies yet.

## Sweep

Take the top four, or the batch size the user gave, and read just enough of
each to say what it is. Ask about them in one AskUserQuestion call, one
question per issue, at most four per call. Each question names the issue,
says what it asks for and what deciding it unlocks, such as "Unlocks #22,
#23 and 3 more in milestone 4", and offers:

- **Decide now:** work through it in this session. Its description says what
  that involves: refining an Inbox issue, or the open questions waiting on a
  Needs decision one.
- **Skip:** leave it as it is. It comes back in a later session.
- **Archive:** close it as Dropped.

Put your recommendation first, with "(Recommended)" after its label: usually
Decide now, or Archive for an issue that is obsolete, a duplicate or already
done.

## Decide

Go through the issues the user chose to decide now, in ranking order:

1. **Refine.** Read the issue, its comments, the records in `decisions/` that
   touch it and the code it would change. Settle what the workflow leaves to
   you. What is the user's call is a question; for an issue the user didn't
   ask for, whether it is worth doing is one of them.
2. **Ask.** With no questions left, skip to the next step. Otherwise ask them
   in one AskUserQuestion call for the issue, up to four at a time, each with
   options and your recommendation first. Each question stands on its own,
   naming the issue and what the choice changes.
3. **Record and move on.** Write what was settled and answered on the issue,
   so that it can be built without further conversation, and move it to
   Ready. If the user leaves a question open, write it on the issue with its
   options and move the issue to Needs decision.

Archive each issue the user chose to archive: close it as Dropped, with a
one-line comment giving their reason, or saying it was dropped in triage.

## Next batch

Report in a few lines what became Ready, what stays in Needs decision and
what was archived. If candidates remain, ask in one AskUserQuestion question
whether to sweep the next batch, saying how many are left.

## On GitHub

One REST call lists the open issues with their labels, milestone and native
blockers, where `blocked_by` counts open blockers only and `blocking` the open
issues it holds up. Keep `body` too when blockers are lines in it.

```sh
gh api 'repos/OWNER/REPO/issues?state=open&per_page=100' --paginate --jq '.[] | select(.pull_request | not) | {number, title, labels: [.labels[].name], milestone: .milestone.title, blocked_by: .issue_dependencies_summary.blocked_by, blocking: .issue_dependencies_summary.blocking}'
```

`gh api repos/OWNER/REPO/issues/N/dependencies/blocking` names the issues one
holds up, and
`gh api -X PATCH repos/OWNER/REPO/issues/N -f state=closed -f state_reason=not_planned`
closes one as not planned.
