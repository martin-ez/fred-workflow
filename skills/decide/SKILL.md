---
name: decide
description: >
  Go through the Inbox and Needs decision issues with the user, four at a
  time, those that unlock the most first: each is decided now, skipped or
  archived. Use when the user asks to triage, refine or decide issues, or to
  go through the inbox.
argument-hint: "[batch size] [area or milestone to focus on]"
---

# Decide

1. **Rank** the open Inbox and Needs decision issues, kept to the user's
   focus if they named one, leaving out those handled or skipped in this
   session. Rank by what deciding each unlocks, judged across the project and
   not only from links: the issue becoming Ready and the issues waiting on
   it; what the user or agents could do that they can't now, such as checking
   their own work or previewing a branch; and what it opens up, such as
   something people can start using, a risk retired or several issues settled
   by one answer. Earlier stages of the roadmap count more. Rank from the
   issue list, the roadmap and what you know of the project, and open an
   issue only when its title leaves its value unclear.
2. **Sweep** the top four, or the batch size the user gave, with one
   AskUserQuestion question per issue, at most four per call. Each question
   says what the issue asks for and what deciding it unlocks, and offers:
   - **Decide now**, saying what that involves, such as refining it or the
     questions waiting on it.
   - **Skip:** leave it as it is until a later session.
   - **Archive:** close it as Dropped.

   Put your recommendation first, marked "(Recommended)": usually Decide now,
   or Archive for an issue that is obsolete, a duplicate or already done.
3. **Decide** the chosen issues, highest ranked first. Read each with its
   comments, the records in `decisions/` and the code it touches, and settle
   what the workflow leaves to you. Ask the rest in one AskUserQuestion call
   per issue, up to four questions, each naming the issue, recommendation
   first. For an issue the user didn't ask for, one question is whether it's
   worth doing. Write the outcome on the issue so it can be built without
   further conversation, and move it to Ready, or to Needs decision with any
   question left open.
4. **Archive** the issues the user chose to, with a one-line comment giving
   their reason, or saying it was dropped in triage.
5. **Report** what became Ready, what waits on a decision and what was
   archived, then ask whether to sweep the next batch, saying how many
   remain.

On GitHub, the REST issue list gives each issue's
`issue_dependencies_summary`, where `blocked_by` counts open blockers and
`blocking` the open issues it holds up.
