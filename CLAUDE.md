# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run locally (SQLite in-memory + mocked auth)
npm start                        # cds-serve on http://localhost:4004

# Watch mode (auto-restart on file changes)
cds watch                        # development profile (SQLite)
npm run watch:hybrid             # hybrid profile (HANA cloud + mocked auth)

# Compile CDS only — fastest way to catch model errors
npx cds compile srv/

# Production MTA build + CF deploy
npm run build                    # outputs mta_archives/archive.mtar
npm run deploy
```

**Hybrid mode setup (once per BAS session):**
```bash
cds bind -2 hr-sf-emp-data-db   # writes .cdsrc-private.json with HANA credentials
npm run watch:hybrid
```

**Test OData endpoints locally:**
```bash
# Local dev (Basic Auth)
curl -u david.brown:david  "http://localhost:4004/odata/v4/leave/LeaveRequests"
curl -u bob.smith:bob      "http://localhost:4004/odata/v4/manager/TeamRequests"
curl -u alice.johnson:alice "http://localhost:4004/odata/v4/hradmin/LeaveBalances"

# BAS browser URLs (sap-user param sets auth cookie for all subsequent requests)
# emp_ui: …/emp_ui/webapp/index.html?sap-user=david.brown
# mgr_ui: …/mgr_ui/webapp/index.html?sap-user=carol.white
```

**Test leave workflow actions via curl:**
```bash
BASE="http://localhost:4004/odata/v4/leave"
# Submit
curl -s -X POST "$BASE/LeaveRequests(<ID>)/submit" \
  -u david.brown:david -H "Content-Type: application/json" -d '{"notes":"..."}'
# Approve (manager)
curl -s -X POST "http://localhost:4004/odata/v4/manager/TeamRequests(<ID>)/approve" \
  -u bob.smith:bob -H "Content-Type: application/json" -d '{"comments":"..."}'
# Reject (manager)
curl -s -X POST "http://localhost:4004/odata/v4/manager/TeamRequests(<ID>)/rejectRequest" \
  -u bob.smith:bob -H "Content-Type: application/json" -d '{"reason":"..."}'
# Withdraw / cancel (employee)
curl -s -X POST "$BASE/LeaveRequests(<ID>)/withdraw" \
  -u david.brown:david -H "Content-Type: application/json" -d '{"reason":"..."}'
```

## Architecture

### Layer overview

```
db/schema.cds                    → Domain model (namespace sap.hr)
srv/leave-service.cds            → LeaveService + HRAdminService projections & actions
srv/leave-service-auth.cds       → @restrict annotations for LeaveService + HRAdminService
srv/leave-service.js             → Handlers for LeaveService + HRAdminService
srv/manager-service.cds          → ManagerService projections & actions
srv/manager-service-auth.cds     → @restrict annotations for ManagerService
srv/manager-service.js           → Handlers for ManagerService
server.js                        → Custom express bootstrap (BAS auth bypass middleware)
app/emp_ui/annotations.cds       → Fiori Elements V4 UI annotations for emp_ui
app/mgr_ui/annotations.cds       → Fiori Elements V4 UI annotations for mgr_ui
app/services.cds                 → Re-exports both annotation files into the CDS model
```

### Three services

| Service | Mount | Who uses it |
|---------|-------|-------------|
| `LeaveService` | `/odata/v4/leave` | Employees & Managers (draft-enabled `LeaveRequests`) |
| `ManagerService` | `/odata/v4/manager` | Managers only — `TeamRequests` (not draft-enabled) |
| `HRAdminService` | `/odata/v4/hradmin` | HR Admins only — raw projections + bulk actions |

`ManagerService` is a separate service (not just an annotation). Its balance mutations bypass the service entity and use `cds.connect.to('db')` directly to avoid the `TeamLeaveBalances` WHERE restriction.

`HRAdminService` handler is exported from `leave-service.js` as `module.exports.HRAdminService` and exposes two unbound actions: `allocateAnnualLeave` and `processCarryForward`.

### MTA deployment (CF)

Three deployed modules from `gen/`:
- `hr-sf-emp-data-srv` — Node.js CAP server (`gen/srv`)
- `hr-sf-emp-data-db-deployer` — HANA HDI deployer (`gen/db`)
- `hr-sf-emp-data-app-deployer` — HTML5 apps (`gen/app/comsapsfempui.zip`, `gen/app/comsapsfmgrui.zip`)

Run `npx cds build --production` (or `npm run build`) to regenerate all `gen/` artifacts before deploying.

### BAS auth bypass (`server.js`)

The BAS HTTPS proxy suppresses Basic Auth popups. `server.js` adds an Express middleware (via `cds.on('bootstrap')`) that:
1. Reads `?sap-user=<username>` from the query string on the first request
2. Injects the correct `Authorization: Basic` header (password looked up from `package.json` config)
3. Sets a `sap-mock-user` response cookie so all subsequent OData calls from the UI5 app authenticate as the same user without repeating the param
4. Deletes incoming session cookies to prevent stale logins bleeding through

Only active when `cds.env.requires.auth.users` is populated (i.e., mocked auth). Safe to leave in production — XSUAA middleware owns auth there.

### Critical design decisions

**`managerId` stores `userId`, not `employeeId`.**
`Employees.managerId : String(100)` holds the manager's login name (e.g. `bob.smith`), not `EMP002`. This allows CAP `@restrict where` clauses to compare directly against `$user`. Never change this to store `employeeId` — it would break all manager-scoped auth rules.

**Action named `rejectRequest`, not `reject`.**
`cds.ApplicationService` has a built-in `reject()` method. Shadowing it with a custom action causes undefined behaviour. The action is `rejectRequest` everywhere.

**`@cds.redirection.target` on `LeaveRequests`.**
Both `LeaveRequests` and `TeamLeaveRequests` in `LeaveService` project `hr.LeaveRequests`. CDS requires one canonical navigation target; `LeaveRequests` carries the annotation.

**`criticality` is a `virtual` field, computed in JS, not a CASE expression in CDS.**
HANA's hdb driver parameterises CASE expression THEN-values and infers their type as NVARCHAR, rejecting integer returns (3/2/1/0) with "Argument must be a string". The field is declared `virtual criticality : Integer` and set in the `after('READ')` handler:
```js
r.criticality = r.status === 'APPROVED' ? 3 : r.status === 'PENDING' ? 2 : r.status === 'REJECTED' ? 1 : 0;
```
This applies to both `LeaveService` (`leave-service.js` `_afterRead`) and `ManagerService` (`manager-service.js` `after('READ', TeamRequests)`).

**Balance mutations must use `'sap.hr.LeaveBalances'` string, not `this.entities.LeaveBalances`.**
In `LeaveService`, the balance entity is exposed as `MyLeaveBalances` (with a `where: employee.userId = $user` restriction). Destructuring `LeaveBalances` from `this.entities` returns `undefined`. All `_getBalance`, `_updatePending`, `_updateUsed`, `_refreshRemaining` helpers are called with the string `'sap.hr.LeaveBalances'` to bypass service auth and access any employee's balance.

**Virtual boolean flags drive button visibility.**
`submitEnabled`, `approveEnabled`, `rejectEnabled`, `cancelEnabled`, `withdrawEnabled` are set in `after('READ')` based on `status` and `req.user.is('Manager')`. `Core.OperationAvailable` pointing to `false` hides buttons on the Object Page and disables them on the List Report toolbar. Do not use `$edmJson` or `@UI.Hidden` patterns — they don't hide buttons on the Object Page.

**Auth annotations in separate files.**
All `@restrict` annotations live in `*-auth.cds` files, not in the service definitions. CDS picks them up automatically.

### Status lifecycle

```
DRAFT → (submit) → PENDING → (approve) → APPROVED → (withdraw) → WITHDRAWN
                           → (rejectRequest) → REJECTED
DRAFT or PENDING → (cancel) → CANCELLED
```

Enforced by both `@flow.status` annotation and explicit guards in each action handler.

### Balance accounting

`remaining = allocated + carryForward - used - pending`

- `submit`: `pending += days`
- `approve`: `pending -= days`, `used += days`, recalculate `remaining`
- `rejectRequest` / `cancel`: `pending -= days`, recalculate `remaining`
- `withdraw`: `used -= days`, recalculate `remaining`

`_refreshRemaining()` always recalculates from all components rather than applying a delta.

### Mock users (development + hybrid)

Defined in `package.json` under `cds.requires.[development].auth.users` and duplicated under `[hybrid]`:

| Username | Password | Role | Reports to |
|----------|----------|------|------------|
| alice.johnson | alice | HRAdmin | (top) |
| bob.smith | bob | Manager | alice.johnson |
| carol.white | carol | Manager | alice.johnson |
| david.brown | david | Employee | bob.smith |
| emma.davis | emma | Employee | bob.smith |
| frank.miller | frank | Employee | carol.white |

Production auth uses XSUAA (`[production].auth: "xsuaa"`).

### HANA-specific pitfalls

- **CSV field count**: `sap.hr-LeaveRequests.csv` must have exactly 23 fields per row (header + 22 data columns). The file exists in both `db/data/` and `gen/db/src/gen/data/` — keep them in sync.
- **CASE expressions in projections**: Do not use `case ... when 'X' then N` or `case when col = 'X' then N` in CDS entity projections queried at runtime. HANA's hdb driver parameterises the THEN values and type-infers incorrectly. Compute such values in JS `after('READ')` handlers instead.
- **Working day calculation**: `_calcWorkingDays()` counts Mon–Fri only with no public holiday awareness. Replace for production use.
