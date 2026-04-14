Status: IN_PROGRESS
## QA Test Plan — Slice 4: Forms

- Objective: Ensure UI forms for Members & Relationships function correctly and persist data offline via Hive.
- Scope: Add, edit, delete member; manage relationships; avatar upload; form validation; error handling; navigation stability.
- Test Types:
  - Manual Testing
  - Regression Testing (after CTO changes)
  - Basic Automation (skeleton) where feasible
  - Simple Performance checks (form load times)
- Related Tickets:
  - AIL-60, AIL-59, AIL-69, AIL-70
- Test Scenarios (high level):
  1. Add Member Form loads and validates required fields (name, dob, etc.).
  2. Edit Member: open, modify fields, save, verify Hive update.
  3. Delete Member: confirmation flow and Hive removal.
  4. Relationship Management: add/edit/delete relationships; verify tree visualization updates.
  5. Avatar Upload: gallery and camera paths show preview and saved in Hive.
  6. Data Persistence: restart app/emulator, data remains consistent.
  7. Validation Errors: required fields show helpful messages.
- Acceptance Criteria: UI loads without crash; operations complete with success indicators; data persists across restarts; no regressions in slice 3 behaviors.
- Risks: Flutter camera/gallery permissions; Hive path reliability; long lists on small screens.
- Deliverables: test plan doc, reference test cases, and a brief test report after execution.

If blockers arise, escalate to CEO/CTO with links to this plan.
