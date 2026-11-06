---
name: before-coding
description: Use when starting a software project that needs a durable development baseline, or when project requirements, product behavior, architecture, and verification practices need structured clarification.
---

# Before Coding

Establish a small, accurate set of project documents, then clarify the real product and domain with the user. Treat confirmed behavior as a baseline that later changes must preserve unless the user explicitly approves a baseline change.

## Workflow

1. **Inspect the project first.** Confirm the project root and inspect its existing instructions, README, docs, source layout, package manifests, test configuration, and available verification commands. Report concrete facts separately from assumptions.
2. **Choose the runtime entry points.** Keep `AGENTS.md` as the shared project guidance. For Claude Code, create `CLAUDE.md` as a one-line import of `AGENTS.md` (`@AGENTS.md`) so project rules have one canonical source. Match the project's established documentation language and terminology. Create only the files relevant to this project; do not create empty sections for systems that do not exist.
3. **Handle every path collision before writing.** List the planned files and identify which already exist. Ask how to handle each existing file: keep and skip; review and merge; back up then replace; create alongside under a different name; or stop. Never overwrite or merge an existing file without the user's choice. For instruction files such as `AGENTS.md` and `CLAUDE.md`, show the proposed merge or diff before applying it.
4. **Create concise skeletons.** Use the templates in `assets/templates/` for `AGENTS.md`, `docs/product-contract.md`, `docs/architecture.md`, `docs/verification.md`, and `docs/changes/README.md`. Mark unknowns as `TBD`; do not invent project facts. Create `.before-coding.json` from the matching template only after the user resolves its collision, and record the skill version, initialization date, selected runtime, and files created, skipped, or merged.
5. **Clarify the project with the right grill.** Use `grill-me` to uncover the project's real users, problems, workflows, requirements, boundaries, and acceptance criteria. Use `grill-with-docs` only when existing documents themselves need to be reviewed and their gaps or defects discussed with the user; the mere presence of existing documents is not a reason to use it. If both needs are present, finish requirements discovery with `grill-me` first, then use `grill-with-docs` for the document review. Invoke the selected skill through the current runtime's skill mechanism when available. If unavailable, inspect its instructions if present and follow the same intent directly. Find repository facts yourself; ask the user to decide product intent, priorities, and trade-offs. Ask only questions whose answers are not already established.
6. **Update documents from confirmed answers.** As terms and decisions become clear, record domain vocabulary in `GLOSSARY.md` and hard-to-reverse, surprising trade-offs in `docs/adr/`. Re-check for same-name files immediately before creating artifacts discovered during the interview. Keep glossary entries about domain language only. Update the product contract, architecture, and verification documents with confirmed project-specific information. Distinguish implemented behavior from desired behavior and proposals.
7. **Close with a review, not implementation.** Summarize the resulting project understanding, changed documents, unresolved questions, and suggested next step. Ask the user to confirm that the shared understanding is accurate. This skill does not authorize implementation work; wait for a separate implementation request.

## Document Boundaries

- `AGENTS.md`: short operating rules and links to the project baseline; not a copy of every technical or product document.
- `docs/product-contract.md`: current user journeys, confirmed interaction behavior, invariants, scope, and approved baseline changes.
- `docs/architecture.md`: actual modules, ownership, data flow, integrations, and links to accepted ADRs.
- `docs/verification.md`: verified commands and checks, acceptance scenarios, and known manual verification gaps. Never present an unrun command as verified.
- `docs/changes/`: task-specific agreements or specs for new features and cross-module work. Small fixes can use a concise agreement in chat.
- `GLOSSARY.md`: domain terms only; never implementation notes or a scratchpad.
- `docs/adr/`: create only for decisions that are hard to reverse, surprising without context, and the result of a real trade-off.

## Conflict and Baseline Rules

An existing file belongs to the user, even when it has the expected name. Read it before proposing a merge. Preserve unrelated material, and make conflicts explicit instead of silently choosing between sources.

When code and documentation disagree, do not silently label either one correct. Record the mismatch, inspect evidence, and ask the user when intended behavior cannot be inferred. After an approved change is implemented and verified, update the current baseline; keep dated design notes as history rather than treating them as current truth.

## Completion Checklist

- [ ] Existing project instructions and relevant docs were inspected.
- [ ] Existing-file conflicts were resolved with the user's choice.
- [ ] Unknowns and unverified commands are clearly marked.
- [ ] Confirmed requirements and domain terms are reflected in the right documents.
- [ ] No business code was changed or implementation started.
- [ ] The user has a concise review summary and can confirm the shared understanding.
