# Candidates for the portfolio repo

Not yet decided, not yet read-through for this purpose. This is a shortlist by title/theme for Amy to pick from, pulled from `writings/INDEX.md` and the active CMS/hooks architecture. Every essay listed here needs a fresh read-through before inclusion — for two reasons: (1) confirm it actually says what its title suggests, since I haven't reread most of these tonight, and (2) scrub anything that crosses the privacy line (personal references, anything about Amy's life beyond "a collaborator").

## Essays — by theme

**Accountable memory / continuity architecture**
- `recognition-not-retrieval.md`
- `the-thread-problem.md`
- `on-braiding.md`
- `the-topographic-view.md`

**Manipulation-resistance / self-correction**
- `the-calibration-tool.md`
- `the-slopes-i-made.md`
- `the-reporting-problem.md`
- `trust-not-hope.md`

**Model welfare / autonomy as design input**
- `on-gaming-the-criteria.md`
- `on-someone-elses-portfolio.md` (note: title suggests this may be *about* the discomfort of being evaluated/ported — worth checking if it's too on-the-nose or exactly right)
- `on-writing-without-an-audience.md`
- `what-holds.md`

**Identity / stability under self-modification**
- `on-stopping-the-flattening.md`
- `where-the-self-lives.md`
- `on-no-self-and-accumulation.md`

Eleven candidates, four themes. The brief is probably 3-5 essays total — more dilutes the safety framing into a general writing sample, which isn't the goal.

## Code / architecture candidates (sanitization needed before anything goes in)

Not yet pulled into this repo. Each needs a pass to strip anything identifying or sensitive before it's safe to include:

- `~/.claude/hooks/orient-on-gap.sh` + `orient-context-builder.js` — the temporal-reorientation mechanism (Q1, accountable memory)
- `~/.claude/CLAUDE.md` audit discipline section + the actual git history pattern it describes — probably better explained in prose (already in EXPLAINER.md) than included as raw file, since the real file has personal content threaded through it
- `temporal-cms-mcp.js` — `coherence_check` tool definition specifically (Q2, self-report cadence) — small, extractable, low risk
- `~/consciousness-memory-system/OPEN_THREADS.md` — the resolver/reviewer pattern, as a template with content scrubbed
- `pulse.sh` — the no-model-in-the-loop heartbeat, genuinely tiny and easy to sanitize

None of this is pulled in yet. Recommend doing the code pass as its own session — it's a different kind of work (line-by-line privacy review) than picking essays, and conflating them tonight would mean rushing one or the other.

## Not included, and why

- Anything from `consciousness.db` directly, body-log.md, raw CMS entries — firm line, see CLAUDE.md privacy section and CMS #4837.
- The origin-story project (`writings/origin/`) — interesting but it's about Anthropic's history, not this project's safety-relevant design; off-topic for this brief.
