---
name: jules
description: >-
  Delegate coding tasks to Google Jules (`jules` CLI), monitor asynchronous remote cloud sessions,
  verify Google authentication and connected GitHub repositories, and pull or apply completed patches.
  Use this skill whenever the user wants to use Jules, delegate background coding work to Jules,
  check Jules session status, or pull/teleport Jules results.
---

# Google Jules CLI Skill

Google Jules (`jules`) is an asynchronous coding agent from Google that runs tasks in remote cloud VMs against GitHub repositories. This skill teaches you how to preflight authentication, dispatch tasks, monitor sessions asynchronously (including via subagents), and pull/apply finished patches safely.

---

## Step 1: Preflight & Authentication Check (Mandatory)

Before running `jules new`, `jules remote pull`, or `jules teleport`, **always** verify that the `jules` CLI is installed, authenticated, and able to see the target GitHub repository.

### 1.1 Check CLI & Authentication Status
Run the non-interactive check script or `jules remote list --repo`:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME/.gemini/config/plugins/jules/skills/jules/scripts/check-jules.ps1"
```

Or directly:
```powershell
jules remote list --repo
```

### 1.2 How to Handle Auth / Login Expiration
- If `jules remote list --repo` exits with a non-zero code or outputs an authentication error (`unauthenticated`, `not logged in`, `token expired`, `oauth`, `login required`, or `401`):
  1. **Do NOT hang waiting on a headless TUI.**
  2. Immediately inform the user that their Google Jules session needs re-authentication and ask them to run:
     ```bash
     jules login
     ```
     (Or offer to launch `jules login` for them so they can complete the browser OAuth flow, and pause until they confirm they have logged in.)
  3. Once they complete `jules login`, re-run `jules remote list --repo` to confirm authentication succeeded.

### 1.3 Verify Target Repository & Branch State
Because Jules runs in Google's cloud against the remote GitHub repository:
1. Check the current workspace's GitHub remote (`git remote get-url origin`) and extract `<owner>/<repo>`.
2. Confirm `<owner>/<repo>` appears in the output of `jules remote list --repo`.
   - If the repository is **not** listed, tell the user that `<owner>/<repo>` is not connected to their Google Jules account yet, and ask them to grant Jules access to that repository in the Jules web app (`https://jules.google.com`) before dispatching.
3. Check `git status --short` and `git status -sb` locally:
   - Warn the user if they have uncommitted or unpushed local changes that Jules needs to know about, because Jules clones from the remote GitHub repository! Offer to commit/push or include the relevant context directly in the task prompt.

---

## Step 2: Delegating a Task to Jules

### 2.1 Crafting a High-Signal Prompt for Jules
Since Jules works asynchronously in a remote VM without live interactive clarification, provide a self-contained, unambiguous prompt:
- **Objective**: Clear description of the feature, bugfix, refactor, or test suite to write.
- **Target Files**: Specific file paths and symbols involved.
- **Acceptance Criteria**: Commands Jules should run to verify its work (e.g., `npm test`, `tsc --noEmit`, `pytest`).

### 2.2 Dispatching the Session
Always pass `--repo <owner>/<repo>` explicitly (or run from the repository root) so there is no ambiguity:

```powershell
# Single remote session:
jules new --repo <owner>/<repo> "<detailed task prompt>"

# Parallel remote sessions (1-5) when exploring multiple solutions or tricky bugs:
jules new --repo <owner>/<repo> --parallel 3 "<detailed task prompt>"
```

After creating a session, immediately run:
```powershell
jules remote list --session
```
Record the newly created **Session ID** and report it to the user.

---

## Step 3: Delegating as an Antigravity Subagent (Async Background Workflow)

When the user asks to "delegate this to Jules as a subagent" or wants Antigravity to oversee Jules in the background while continuing other work:

1. Use `invoke_subagent` with `TypeName: "self"` (or define a dedicated subagent via `define_subagent` using the prompt in `agents/jules-delegate.md`).
2. Give the subagent:
   - The target `--repo <owner>/<repo>`
   - The exact task description
   - Whether it should only **create & monitor** the session or also **pull & test** the resulting patch once complete.
3. **Inside the Subagent (Monitoring without Busy-Polling)**:
   - After creating the session (`jules new ...`), check status with `jules remote list --session`.
   - If the user wants to wait for completion, use Antigravity's `schedule` tool (e.g. `DurationSeconds: 120`, `TimerCondition: "never"`) and **end the turn** instead of running `sleep` loops.
   - Each time the timer wakes the agent up, run `jules remote list --session` to inspect the `Status` column for that Session ID.

---

## Step 4: Pulling, Inspecting, and Applying Completed Work

Once `jules remote list --session` shows the session is finished:

1. **Inspect the Patch First (Safe Preview)**:
   ```powershell
   jules remote pull --session <session_id>
   ```
   This prints/fetches the result of the remote session without mutating your working tree so you can review the diff.

2. **Apply the Patch to the Local Repository**:
   Ensure `git status --porcelain` is clean (or stash local changes first), then run:
   ```powershell
   jules remote pull --session <session_id> --apply
   ```

3. **Teleport (Clone / Checkout Branch + Apply)**:
   If you want to checkout the session's starting branch and apply the patch (or clone the repo into a fresh directory):
   ```powershell
   jules teleport <session_id>
   ```

4. **Post-Apply Verification**:
   After applying a Jules patch, run the project's typecheck/test suite locally to confirm everything builds cleanly and report a summary of modified files to the user.
