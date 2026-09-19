# Multi-agent workflow

The repository uses isolated branches/worktrees, explicit file claims, and a
verification gate. Agents must follow this sequence:

1. Read `AGENTS.md`, this file, and `coordination/OWNERS.md`.
2. Start from a clean, up-to-date branch named `codex/<short-task-name>`.
3. Claim the exact files before editing:

   ```sh
   python3 tools/agent-coordination.py claim \
     --agent "your-name" --task "short task" \
     Sources/USMCore/Foo.swift Sources/USMApp/Bar.swift
   ```

4. If the command reports an overlap, stop and coordinate with the owner.
   Reading, testing, and reviewing are allowed; editing is not.
5. Make the smallest coherent change. Do not reformat unrelated files or
   rewrite shared files to resolve a cosmetic issue.
6. Run `./tools/agent-check.sh` during development and again before handoff.
7. Announce the proposed change in the task/PR and allow the owner/reviewer
   objection window to pass. An objection must identify a concrete conflict,
   regression, or missing acceptance criterion; silence is approval only after
   the stated window.
8. Rebase or merge the latest `main`, rerun the checks, and open a PR. Never
   push directly to `main`.
9. Release claims after merge or abandonment:

   ```sh
   python3 tools/agent-coordination.py release --claim CLAIM_ID
   ```

The claim registry lives below Git's common directory, not in the worktree.
That makes it visible to sibling worktrees and avoids committing lock files or
claim churn. It is local coordination; the PR and CI checks remain the source
of truth for changes shared with remote agents.

## Handoff message

Every handoff should include: goal, files changed, claim IDs, assumptions,
tests run and results, migration/save-risk notes, screenshots for UI changes,
and any unresolved objection. A reviewer should be able to reject a change
before merge without reconstructing the agent's context.
