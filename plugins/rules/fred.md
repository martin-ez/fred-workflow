# FRED

In cloud sessions, `gh issue` and `gh pr` fail, because the GitHub proxy there rejects GraphQL. Use the REST API through `gh api` instead, for example `gh api repos/OWNER/REPO/issues/N/labels -f 'labels[]=status:in-progress'` to add a label and `gh api -X DELETE repos/OWNER/REPO/issues/N/labels/status:ready` to remove one.

## github.com/martin-ez/foyer
Tracker: GitHub Issues in martin-ez/foyer
Statuses: one `status:` label on each open issue (`status:inbox`, `status:needs-decision`, `status:ready`, `status:in-progress`, `status:in-review`); Done is an issue closed as completed, Dropped is an issue closed as not planned
Source: a `source:user` or `source:agent` label
Blockers: GitHub's native "blocked by" issue dependency (REST `POST /repos/martin-ez/foyer/issues/{number}/dependencies/blocked_by` with the blocking issue's `issue_id`; `GET` on the same path lists them)
Done: the pull request description says "Closes #N", with the keyword before every issue; squash-merging into `main` closes each one as completed
Background research is kept outside the repository, on the user's machine only; never commit it.
