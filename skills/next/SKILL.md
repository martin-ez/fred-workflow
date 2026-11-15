---
name: next
description: >
  Pick the next issue to work on: rank the Ready issues with no open blockers
  against the roadmap and let the user choose, recommendation first. Use when
  the user asks what to work on next or where to start.
argument-hint: "[area or milestone to focus on]"
---

# Next

1. **Gather.** List the open issues with their status, milestone and open
   blockers. The candidates are the Ready issues with no open blockers, kept
   to the user's focus if they named one. Read each candidate and the
   roadmap: milestones, a project board or priority labels.
2. **Rank** by what does the most for the roadmap:
   - Earlier stages first, finishing a stage before starting the next.
   - What it unlocks, judged across the project and not only from links: the
     issues waiting on it, what the user or agents could do that they can't
     now, and what it opens up, such as something people can start using or
     a risk retired.
   - Lower when it would touch the same code as work In progress or In review.
3. **Ask** in one AskUserQuestion question, with up to four candidates, best
   first and marked "(Recommended)". Label each with its number and a few
   words. Describe in one or two sentences what will exist when it's done and
   why now, and put its milestone, what it unlocks, what it needs from the
   user and its size in the preview. Since the dialog may hide your message,
   the question says how many issues are Ready and unblocked, and what holds
   up the rest. With one candidate, offer `/fred:decide` as the other option;
   with none, say so and suggest it.
4. **Start** the chosen issue: check that it is still Ready and unclaimed,
   move it to In progress and Execute it. If the user answers in their own
   words, follow them.

On GitHub, the REST issue list gives each issue's
`issue_dependencies_summary`, where `blocked_by` counts open blockers and
`blocking` the open issues it holds up.
