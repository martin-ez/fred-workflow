# Preferred tools

I have no preferred stack: languages, frameworks and architecture are discussed per project, based on its needs. For the services around a project, propose these first:

- **Version control:** GitHub. Set new repositories to allow only squash merges, with the pull request's title and description as the commit message, to delete branches automatically once merged, and add a ruleset that requires a pull request for every change to `main`, with no required approvals and no bypass. The free plan only allows rulesets on public repositories, so for a private one, ask whether to make it public.
- **Backend for prototypes and small projects:** Firebase, on the free Spark plan.
- **Infrastructure:** Cloudflare, on the free plan.

Stay within the free tiers. When a design would need a paid plan (Cloud Functions, for example, need Firebase's Blaze plan), say so before relying on it.
