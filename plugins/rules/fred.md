# FRED

In cloud sessions, `gh issue` and `gh pr` fail, because the GitHub proxy there rejects GraphQL. Use the REST API through `gh api` instead, for example `gh api repos/OWNER/REPO/issues/N/labels -f 'labels[]=status:in-progress'` to add a label and `gh api -X DELETE repos/OWNER/REPO/issues/N/labels/status:ready` to remove one.

On GitHub, the REST issue list gives each issue's `issue_dependencies_summary`, where `blocked_by` counts its open blockers and `blocking` the open issues it holds up, so ranking issues by blockers needs no call per issue.
