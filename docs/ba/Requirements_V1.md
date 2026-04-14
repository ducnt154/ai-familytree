# BA Requirements (Version 1)

This document captures initial business analysis artifacts:
- User stories
- Acceptance criteria
- Scope notes and non-goals

## 1) Epic: Guided Onboarding & Education
- User Story 1: Onboarding with risk assessment
  - As a new user, I want to complete a quick risk-quiz so the app can tailor guidance to my risk tolerance.
  - Acceptance Criteria:
    - A short quiz (5-7 questions) with clear explanations
    - Risk profile result is stored and used to customize recommendations
    - On completion, user sees a first-step learning path and starter investment plan

- User Story 2: Goal-based setup
  - As a user, I want to set financial goals (retirement, education, major purchase) to shape my investment plan.
  - Acceptance Criteria:
    - Users can create multiple goals with target dates and amounts
    - Goals appear in a dedicated dashboard and influence recommended allocations

- User Story 3: Education micro-lessons
  - As a user, I want short, actionable lessons embedded in the app to learn investing basics.
  - Acceptance Criteria:
    - Lessons are scannable, with key takeaways and quizzes
    - Completion of lessons increases user confidence score in the plan builder

## 2) Epic: Unified Investment Planner
- User Story 4: Plan builder integration
  - As a user, I want a simple plan builder that translates goals and risk profile into an investment plan.
  - Acceptance Criteria:
    - Plan builder suggests asset allocation ranges based on risk score
    - User can adjust allocation and see projected outcomes (simple charts)
    - Saving/applying the plan updates the user’s dashboard

- User Story 5: Budget integration (basic)
  - As a user, I want basic budgeting inputs that connect to my investment plan (e.g., monthly invest amount).
  - Acceptance Criteria:
    - User can set monthly invest amount constraints
    - Changes reflect in allocation and projected outcomes

## 3) Epic: Simple Portfolio Analytics
- User Story 6: Real-time-ish analytics
  - As a user, I want to view simple portfolio performance metrics (return, volatility, allocation) in a clean UI.
  - Acceptance Criteria:
    - Performance metrics update on demand (no external delays)
    - Allocation heatmap/ pie chart is available
    - Data is clearly sourced and timestamped

- User Story 7: Auto-rebalancing (conceptual)
  - As a user, I want auto-rebalancing suggestions explained clearly (not automatic changes yet).
  - Acceptance Criteria:
    - UI shows suggested rebalancing actions with rationale
    - User can accept/refuse each action

## 4) Scope & Non-goals
- Scope: onboarding, education, plan builder, basic analytics, and UI/UX for investment guidance.
- Non-goal: fully automated trading execution, tax optimization engine in v1; those may be future variants.
