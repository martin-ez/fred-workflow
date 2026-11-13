---
name: strict-tests
description: >
  Enforce strict test rules on the current branch diff: test only public
  members, cover every interaction point of what changed, and never assert on
  implementation details (DOM structure, styling, internal calls, mocks of
  internal modules). Violating tests are rewritten or deleted and missing
  coverage is written directly.
---

# Strict Tests

This skill enforces three hard rules for tests on any PR or code change. It
scans the **current branch diff** and **directly fixes** every violation:
bad tests are rewritten or deleted, and missing tests are written. The rules
are not judgment calls — a test that breaks one of them is a violation even
if it currently passes and looks thorough.

## The three rules

1. **Only public members are tested.** Private and internal logic is subject
   to change and is never tested directly. It is exercised only through the
   public members that use it.
2. **Every interaction point is covered.** For a UI component, every action a
   user can perform on it. For a class or module, every member of its public
   interface that has behavior. Each test asserts an observable outcome.
3. **Never test design or implementation details.** Tests assert *what* the
   code produces — the information a component displays, the value a
   function returns, the events it emits — never *how* it does it.

## Workflow

1. **Get the diff.** Find the base branch
   (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main` or
   `master`) and read the added/modified hunks with `git diff <base>...HEAD`.

2. **Split the diff into two lists.**

   - **Tests touched:** every test file or test case added or modified.
   - **Subjects touched:** every public member (see definitions below) added
     or whose behavior changed in a non-test file.

3. **Audit each touched test against the three rules.** A test must pass all
   three to stay. Read the file under test to know what is public and what
   the contract is; do not judge a test from the test file alone.

4. **Audit each touched subject against rule 2.** Enumerate its interaction
   points and check that a test exists for each — in the diff or already in
   the repo. Anything uncovered is a rule 2 violation.

5. **Fix violations.** Use the `Edit` tool; read each file before editing.
   How to fix depends on the rule broken:

   - **Rule 1 (tests a private):** delete the test. If the private logic is
     complex enough that it deserves its own tests, either extract it into
     its own public unit (a function, class, or module with a real name and
     a real contract) or mark it with the language's test-visibility
     annotation (`@VisibleForTesting`, `@testable`, `internal` + test
     module access). A member annotated this way is treated as public: it
     has a contract, and its tests follow rules 2 and 3 like any other.
   - **Rule 2 (missing coverage):** write the missing test. Follow the
     conventions of the surrounding tests: same framework, same file
     layout, same helpers. One behavior per test, named after the behavior.
   - **Rule 2 (no observable assertion):** rewrite the test to assert the
     outcome. If there is no outcome to assert, the test has no reason to
     exist — delete it.
   - **Rule 3 (implementation detail):** rewrite the assertion against the
     public contract: the rendered text or accessible role, the return
     value, the thrown error, the emitted event, the call on an injected
     boundary. If nothing observable is left once the detail is removed,
     delete the test.

6. **Run the tests you touched** with the project's test runner and confirm
   they pass. A test you wrote must also be shown to fail when the behavior
   it guards is broken — if you cannot describe the change that would make
   it fail, it is not a real test.

7. **Report.** Print a per-file summary: `path:line` → rule broken + fix
   applied, then totals.

## What the rules mean in practice

### Public members

- The exported/visible API surface: public classes, functions, methods,
  fields, hooks, exported components, HTTP routes, CLI commands.
- Private = language-private (`_name` in Dart/Python, `private`/`internal`
  in Kotlin/Java/TS, unexported in Go, non-`pub` in Rust, not exported from
  the module in JS/TS) or file/module-local helpers.
- **Test-visibility annotations are the sanctioned way to expose a member.**
  `@VisibleForTesting`, `@testable`, and equivalents declare that a member is
  part of the tested contract. Use them deliberately, for logic that is
  worth testing on its own but does not belong in the public API.
- **Bypassing visibility is a rule 1 violation.** No reflection,
  `// @ts-ignore` to reach a private, reading `_fields` from a test, or a
  bare `export` added only so a test can import it. If a test needs the
  member, annotate it or extract it.
- **Internal modules are private to the package.** A helper module that is
  not part of what the package exports is tested only through the exports.

### Interaction points

- **UI component:** each user action — click, tap, type, submit, select,
  toggle, drag, keyboard navigation, focus/blur — plus each distinct input
  state the component renders differently (empty, loading, error, populated,
  disabled).
- **Class / module:** each public member that has logic of its own. Its
  contract includes the happy path, the boundaries, and the error cases the
  signature or docs promise.
- **A member with no logic is not an interaction point.** Plain getters,
  pass-through constructors, `toString`, re-exports, and trivial delegation
  do not get their own tests. Covering them is padding, not coverage.
- **Every test asserts an observable outcome.** "Renders without crashing",
  `expect(wrapper).toBeTruthy()`, "does not throw", and a bare
  `toHaveBeenCalled()` on a mock with no assertion on the result are not
  tests. Delete or rewrite them.

### Implementation details

Never assert on any of these:

- **UI:** DOM structure, tag names, CSS classes, inline styles, layout,
  colors, which child component rendered, component internal state, hook
  call order, snapshots.
- **Classes / modules:** private state, the order of internal calls, which
  private helper ran, the shape of intermediate data, how many times an
  internal function was invoked.
- **Mocks of internal modules.** Module-mocking a file inside the same
  package (`jest.mock('./helpers')`, `patch('mypkg.utils.fn')`) and asserting
  on it tests the wiring, not the behavior. Let the real code run.
- **Tautologies.** Mocking a dependency to return X and asserting X came back
  tests the mock framework. Every test must be able to fail on a real bug.

Instead assert on:

- **UI:** visible text, accessible roles and names, form values, what the
  user can and cannot do next, callbacks passed in as props being invoked
  with the right arguments.
- **Classes / modules:** return values, thrown errors, emitted events,
  public state after the call, persisted results readable through the
  public interface.
- **Injected boundaries.** Asserting a call on a collaborator is legitimate
  when the collaborator enters through the public interface (constructor,
  props, parameters) **and** the call *is* the behavior: "sends an email",
  "writes the record", "fetches from the API". This is the contract, not the
  implementation.

## Constraints

- **Stay in the diff.** Only audit tests and subjects in added or modified
  hunks. Pre-existing tests are out of scope, even if they violate the
  rules — unless a subject in the diff changed behavior and its existing
  test now asserts a detail that broke.
- **Never modify non-test code** except to extract a public unit under a
  rule 1 fix — and then change only what the extraction requires. No
  refactors, no "while I'm here" fixes.
- **Never weaken a test to make it pass.** If a rewritten test fails, the
  code has a bug or the contract is misunderstood; report it, do not delete
  the assertion.
- **Match the repo's conventions.** Use the existing test framework, file
  naming, fixture helpers, and query style (e.g. `getByRole` over
  `container.querySelector` in Testing Library). Do not introduce a new
  testing dependency.
- **Applies to every language and UI framework alike.**

## Final report

End with a short verdict block:

```
strict-tests summary
  src/foo.test.ts        2 deleted (rule 1), 1 rewritten (rule 3)
  src/Bar.test.tsx       3 written (rule 2), 1 rewritten (rule 2: no assertion)
  src/foo.ts             1 extracted → src/parseRange.ts (rule 1)
  ─────────────────────────────────────────────
  totals                 7 violations fixed, 0 remaining
  test run               42 passed, 0 failed

uncovered — could not write a test, needs a decision:
  src/Baz.tsx:80  drag-to-reorder has no test; repo has no pointer-event helper
```
