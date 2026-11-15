# fred-workflow

FRED (File, Refine, Execute, Decide) is a minimal workflow for agentic
development. It gives agents as much autonomy as possible while keeping the
important architecture and UX decisions with the humans, recorded in each
project's `decisions/` so agents ask less over time. The whole workflow is
[`WORKFLOW.md`](WORKFLOW.md).

FRED stays out of your code. It adds two things to a project: its
`decisions/`, and `.claude/fred.md`, which says how the project's tracker
works. A session-start hook adds the workflow to every project that has one:

```md
Tracker: GitHub Issues in martin-ez/app
Statuses: one `status:` label; Done and Dropped are closed issues
Source: a `source:user` or `source:agent` label
Blockers: a "Blocked by #N" line in the body
Done: the pull request says "Closes #N", with the keyword before every issue
```

Your own rules for every project go in your registry, `~/.claude/fred.md`. It
can also hold a section for a project that keeps no settings of its own, named
after its repository, matched against the project's `origin` remote wherever
it is cloned, or after a folder such as `~/_dev/martin-ez/app`:

```md
# FRED

<your rules for every project>

## github.com/martin-ez/app
<the same lines as a project's .claude/fred.md>
```

Point `FRED_REGISTRY` at another file to use it instead of
`~/.claude/fred.md`, as a cloud environment does.

To start a session, run `/fred:next`, optionally followed by an area or
milestone to focus on. It reviews the Ready issues with no open blockers,
weighs them against the roadmap, and asks which one to take, recommendation
first, with a short description of each.

## Install

```sh
claude plugin marketplace add martin-ez/fred-workflow
claude plugin install fred@fred-workflow
```

To work on it, load a checkout with a test registry:
`FRED_REGISTRY=/tmp/fred.md claude --plugin-dir ~/_dev/martin-ez/fred-workflow`.
To release, bump `version` in `.claude-plugin/plugin.json`, run
`claude plugin tag`, push, and `claude plugin update fred`.
`sh tests/run.sh` tests the hooks; it needs `jq` and `git`.

## The maintainer's rules

`plugins/rules` holds the maintainer's own setup, published so that local and
cloud sessions read it from one place:

- Skills for pull request text, tests and comments: `strict-pr`,
  `strict-tests` and `strict-comments`.
- Hooks that block pushing code or opening a pull request until the test and
  comment skills have run, check pull request text before it is published, and
  stop agents from merging.
- The FRED registry, `fred.md`, and the user instructions, `instructions.md`.
- User settings, `user-settings.json`, which turn off the attribution Claude
  Code adds to commits and pull requests.

Locally, install it with `claude plugin install rules@fred-workflow`, link
`~/.claude/fred.md` and `~/.claude/CLAUDE.md` to those two files in a
checkout, and merge `user-settings.json` into `~/.claude/settings.json` with
`sh cloud/merge-settings.sh plugins/rules/user-settings.json ~/.claude/settings.json`.
Release it like the workflow, from its own folder.

## Cloud sessions

Cloud sessions don't install plugins from settings, so a cloud environment
fetches this repository before Claude Code starts and loads both plugins from
disk. Give the environment a setup script that runs `cloud/setup.sh`:

```bash
#!/bin/bash
curl -fsSL https://raw.githubusercontent.com/martin-ez/fred-workflow/main/cloud/setup.sh | bash
```

and these environment variables:

```text
CLAUDE_CODE_PLUGIN_DIRS=/opt/claude/fred-workflow:/opt/claude/fred-workflow/plugins/rules
FRED_REGISTRY=/opt/claude/fred-workflow/plugins/rules/fred.md
```

The environment keeps what the script fetched for about a week; edit the setup
script to fetch again sooner. When the script can't clone the repository, it
downloads the files listed in `files.txt`, so update that list with
`git ls-files > files.txt` when adding or removing a file.
