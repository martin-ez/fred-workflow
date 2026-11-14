# FRED

In cloud sessions, `gh issue` and `gh pr` fail, because the GitHub proxy there rejects GraphQL. Use the REST API through `gh api` instead, for example `gh api repos/OWNER/REPO/issues/N/labels -f 'labels[]=status:in-progress'` to add a label and `gh api -X DELETE repos/OWNER/REPO/issues/N/labels/status:ready` to remove one.

## github.com/martin-ez/foyer
Tracker: GitHub Issues in martin-ez/foyer
Statuses: one `status:` label on each open issue (`status:inbox`, `status:needs-decision`, `status:ready`, `status:in-progress`, `status:in-review`); Done is an issue closed as completed, Dropped is an issue closed as not planned
Source: a `source:user` or `source:agent` label
Blockers: GitHub's native "blocked by" issue dependency (REST `POST /repos/martin-ez/foyer/issues/{number}/dependencies/blocked_by` with the blocking issue's `issue_id`; `GET` on the same path lists them)
Done: the pull request description says "Closes #N", with the keyword before every issue; squash-merging into `main` closes each one as completed
Background research is kept outside the repository, on the user's machine only; never commit it.
Until the first version works end to end, views are plain wireframes: build what a view does, not how it looks, and choose provisional layouts and flows yourself. The owner designs the UX on top once the functionality is proven. UX that shapes data, contracts or sync still needs the owner before it's built, above all how presence and live multiplayer are shown (#15, #58).
The data model is built issue by issue: an issue that adds or changes stored data or a contract sets out its part on the issue (the messages and fields, what's stored where, the ids, who can see it, and how it connects to what exists) and waits in Needs decision for the owner's review.
Never use code names, such as lettered options or nicknames for designs, in the repository, issues or milestones; say what the thing is.
