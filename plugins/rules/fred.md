# FRED

In cloud sessions, `gh issue` and `gh pr` fail, because the GitHub proxy there rejects GraphQL. Use the REST API through `gh api` instead, for example `gh api repos/OWNER/REPO/issues/N/labels -f 'labels[]=status:in-progress'` to add a label and `gh api -X DELETE repos/OWNER/REPO/issues/N/labels/status:ready` to remove one.

