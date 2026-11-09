# fred-workflow

FRED (File, Refine, Execute, Decide) is a minimal workflow for agentic
development. It gives agents as much autonomy as possible while keeping the
important architecture and UX decisions with the humans, recorded in each
project's `decisions/` so agents ask less over time. The whole workflow is
[`WORKFLOW.md`](WORKFLOW.md).

FRED stays out of your code. The only thing it adds to a project is its
`decisions/`; everything else lives in `~/.claude/fred.md`, and a session-start
hook adds the workflow to every project listed there:

```md
# FRED

## ~/_dev/martin-ez/app
Tracker: GitHub Issues in martin-ez/app
Statuses: one `status:` label; Done and Dropped are closed issues
Source: a `source:user` or `source:agent` label
Blockers: a "Blocked by #N" line in the body
Done: the pull request says "Closes #N", with the keyword before every issue
```

## Install

```sh
claude plugin marketplace add martin-ez/fred-workflow
claude plugin install fred-workflow@fred-workflow
```

To work on it, load a checkout with a test registry:
`FRED_REGISTRY=/tmp/fred.md claude --plugin-dir ~/_dev/martin-ez/fred-workflow`.
To release, bump `version` in `.claude-plugin/plugin.json`, run
`claude plugin tag`, push, and `claude plugin update fred-workflow`.
