---
name: create-plan
description: Use when the user explicitly asks for a plan before implementation. Do not use for direct implementation requests unless asked to plan first.
---

# Create Plan

## Goal
Produce a clear, actionable implementation plan that can be reviewed and approved before any code is written.

## Workflow
1. Understand the objective and scope from the user's request and relevant docs.
2. Identify affected files, modules, and dependencies.
3. Break the work into discrete, ordered steps.
4. Note assumptions, risks, and open questions.
5. Present the plan for user review before proceeding.

## Output
Return:
- Objective summary
- Ordered step list with file-level specificity
- Assumptions made
- Risks or blockers
- Explicit prompt: "Shall I proceed with this plan?"

## Guardrails
- Do not write or modify code until the plan is approved.
- Flag any step that is irreversible or has wide blast radius.
