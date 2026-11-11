<#
.SYNOPSIS
    G3 - migration / schema gate (blocking).

.DESCRIPTION
    WHAT THIS GATE CHECKS
      1. tools/gates/g3_schema_check.mjs runs green.  That script is the
         repository's schema self-check: DDL executes, the 14 tables are
         exactly the expected set, key indexes exist, PRAGMA
         integrity_check = ok, foreign keys are on, and CHECK / UNIQUE /
         FOREIGN KEY constraints really reject bad data.
      2. The empty-database -> v1 migration smoke test passes: a fresh
         in-memory SQLite database is created from docs/schema_v1.sql,
         then PRAGMA integrity_check, the table set, the key indexes and
         the constraint teeth (bad quadrant / bad mood / bad habit type /
         orphan check-in must be rejected, a valid habit row must be
         accepted) are verified.
      3. The bad-fixture self test (tools/gates/bad-fixtures/self_test.mjs)
         passes: the bad fixtures really do break the constraints.
      4. TOOTH TEST (this gate must have teeth): the gate builds a
         deliberately broken copy of the schema - every CHECK constraint
         is neutralised into `CHECK (1=1)`, using the same technique as
         tools/gates/bad-fixtures/self_test.mjs - and re-runs the smoke
         test against it.  The smoke test MUST fail on that broken schema.
         If it passes, the gate is toothless and this script fails.

    HOW TO HANDLE A FAILURE
      The failing check lines are printed to stderr.  Fix the schema, the
      migration script or the check itself, then re-run:
          pwsh -File tools/gates/g3_migration.ps1

    EXIT CODE
      0 = pass, 1 = fail.  CI depends on the exit code.

.NOTES
      This file is UTF-8 without BOM and ASCII only, so Windows
      PowerShell 5.1 (which decodes BOM-less files with the system ANSI
      code page) can never mis-decode it into a parse error.
#>
[CmdletBinding()]
param(
    # Schema file to test; defaults to <RepoRoot>/docs/schema_v1.sql
    [string]$SchemaPath = '',
    # Explicit node executable; auto-detected when empty.
    [string]$Node = '',
    # Repository root override (defaults to the parent of tools/gates).
    [string]$RepoRoot = '',
    # Skip the tooth test (not recommended - it is what proves this gate
    # can fail at all).
    [switch]$SkipToothTest,
    # Skip the repository bad-fixture self test.
    [switch]$SkipBadFixtureSelfTest
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if (-not $SchemaPath) {
    $SchemaPath = Join-Path (Join-Path $RepoRoot 'docs') 'schema_v1.sql'
}

function Write-Err {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

function Resolve-Node {
    param([string]$Explicit)
    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return $Explicit }
        throw "node executable not found: $Explicit"
    }
    $onPath = Get-Command node -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    throw 'node not found on PATH. Node 22.5+ is required (node:sqlite).'
}

function Invoke-Tool {
    # Runs a native tool and returns @{ Output = <string>; ExitCode = <int> }.
    # Native stderr is captured, never thrown: under $ErrorActionPreference
    # = 'Stop' Windows PowerShell 5.1 turns native stderr into a
    # terminating error.
    param(
        [string]$Exe,
        [string[]]$ToolArgs,
        [string]$WorkingDirectory
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Push-Location $WorkingDirectory
    try {
        $output = & $Exe @ToolArgs 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
        $ErrorActionPreference = $prev
    }
    if ($null -eq $code) { $code = 0 }
    return @{ Output = $output; ExitCode = $code }
}

function Write-Tail {
    # Prints the last N non empty lines of a tool output to stderr.
    param([string]$Output, [string]$Title, [int]$Max = 30)
    Write-Err $Title
    $lines = @()
    foreach ($line in ($Output -split "`r?`n")) {
        if ($line.Trim().Length -gt 0) { $lines += $line.TrimEnd() }
    }
    $start = [Math]::Max(0, $lines.Count - $Max)
    for ($i = $start; $i -lt $lines.Count; $i++) {
        Write-Err ('  ' + $lines[$i])
    }
}

try {
    $node = Resolve-Node $Node
}
catch {
    Write-Err ('[g3] FAILED: ' + $_.Exception.Message)
    exit 1
}

Write-Host '== G3 migration / schema gate =='
Write-Host ('[g3] node: ' + $node)
Write-Host ('[g3] schema: ' + $SchemaPath)

$failures = @()

if (-not (Test-Path -LiteralPath $SchemaPath)) {
    Write-Err ('[g3] FAILED: schema file not found: ' + $SchemaPath)
    exit 1
}

# ---------------------------------------------------------------------------
# Step 1: the repository schema self check
# ---------------------------------------------------------------------------
$schemaCheck = Join-Path (Join-Path (Join-Path $RepoRoot 'tools') 'gates') 'g3_schema_check.mjs'
Write-Host '[g3] step 1/4: g3_schema_check.mjs'
if (-not (Test-Path -LiteralPath $schemaCheck)) {
    Write-Err ('[g3] FAILED: checker not found: ' + $schemaCheck)
    exit 1
}
$run = Invoke-Tool -Exe $node -ToolArgs @($schemaCheck) -WorkingDirectory $RepoRoot
if ($run.ExitCode -ne 0) {
    Write-Tail -Output $run.Output -Title '[g3] FAILED: g3_schema_check.mjs reported failures'
    $failures += 'g3_schema_check.mjs failed'
}
else {
    Write-Host ('[g3]   OK: ' + (($run.Output -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -Last 1) -join ''))
}

# ---------------------------------------------------------------------------
# Step 2 + 4: the migration smoke test and its tooth test
# The helper script is written to a temp directory at run time, so no new
# file is added to the repository.
# ---------------------------------------------------------------------------
$helperSource = @'
// ActLog G3 helper - generated at run time by tools/gates/g3_migration.ps1
// Modes:
//   check --schema <file>          run the migration smoke test
//   make-broken --schema <file> --out <file>   write a neutralised (broken) copy
import { DatabaseSync } from 'node:sqlite';
import { readFileSync, writeFileSync } from 'node:fs';

const EXPECTED_TABLES = new Set([
  'habit', 'habit_checkin', 'habit_score', 'day_log', 'oplog', 'plan_item',
  'project', 'project_increment', 'project_milestone', 'reminder',
  'settings', 'snapshot_meta', 'sync_state', 'todo',
]);
const NOW = 1760000000000;
const DEV = 'dev-1';

function parseArgs(argv) {
  const out = { mode: argv[0] };
  for (let i = 1; i < argv.length; i += 2) {
    out[argv[i].replace(/^--/, '')] = argv[i + 1];
  }
  return out;
}

// Finds the text span of every `CONSTRAINT <name> <kind>` declaration.
// Ported from tools/gates/bad-fixtures/self_test.mjs.  The bracket
// matching is what makes cross line constraints work: a plain per line
// regex would miss `CONSTRAINT x\n    CHECK (...)`.
function findConstraintSpans(sql, kindPattern) {
  const spans = [];
  const re = new RegExp('CONSTRAINT\\s+(\\w+)\\s+' + kindPattern, 'gi');
  let m;
  while ((m = re.exec(sql)) !== null) {
    const start = m.index;
    const name = m[1];
    const after = sql.slice(start);
    const p = after.indexOf('(');
    let depth = 0;
    let i = p;
    for (; i < after.length; i++) {
      if (after[i] === '(') depth++;
      else if (after[i] === ')') {
        depth--;
        if (depth === 0) { i++; break; }
      }
    }
    spans.push({ start, end: start + i, name });
  }
  return spans;
}

// Neutralises the constraints instead of deleting their text: deleting
// would break the comma structure of the CREATE TABLE body.
function neutralizeConstraints(sql, kindPattern) {
  const spans = findConstraintSpans(sql, kindPattern);
  let out = sql;
  for (const span of spans.sort((a, b) => b.start - a.start)) {
    const replacement = 'CONSTRAINT ' + span.name + ' CHECK (1=1)';
    out = out.slice(0, span.start) + replacement + out.slice(span.end);
  }
  return out;
}

const args = parseArgs(process.argv.slice(2));

if (args.mode === 'make-broken') {
  const good = readFileSync(args.schema, 'utf8');
  const broken = neutralizeConstraints(good, 'CHECK\\b');
  if (broken === good) {
    console.error('neutralise failed: the schema was not changed at all');
    process.exit(2);
  }
  writeFileSync(args.out, broken, 'utf8');
  console.log('  broken schema written: ' + args.out);
  process.exit(0);
}

if (args.mode !== 'check') {
  console.error('unknown mode: ' + args.mode);
  process.exit(2);
}

let failures = 0;
let checks = 0;
function ok(name, cond, extra) {
  checks++;
  if (cond) {
    console.log('  PASS  ' + name);
  } else {
    failures++;
    console.log('  FAIL  ' + name + (extra ? ' :: ' + extra : ''));
  }
}
function expectFail(name, fn) {
  checks++;
  try {
    fn();
    failures++;
    console.log('  FAIL  ' + name + ' :: bad data was accepted, the constraint has no teeth');
  } catch (e) {
    console.log('  PASS  ' + name + ' :: ' + String(e.message).split('\n')[0].slice(0, 60));
  }
}
function expectOk(name, fn) {
  checks++;
  try {
    fn();
    console.log('  PASS  ' + name);
  } catch (e) {
    failures++;
    console.log('  FAIL  ' + name + ' :: valid data was rejected :: ' + String(e.message).split('\n')[0].slice(0, 60));
  }
}

const sql = readFileSync(args.schema, 'utf8');
const db = new DatabaseSync(':memory:');
let ddlError = null;
try {
  db.exec(sql);
} catch (e) {
  ddlError = e;
}
ok('empty database -> v1: the whole DDL executes', ddlError === null, ddlError ? String(ddlError.message) : '');
if (ddlError) {
  db.close();
  process.exit(1);
}

const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").all().map((r) => r.name);
ok('table count = 14 (actual ' + tables.length + ')', tables.length === 14);
ok('table set matches exactly', tables.length === EXPECTED_TABLES.size && tables.every((t) => EXPECTED_TABLES.has(t)), tables.join(','));

const integrity = db.prepare('PRAGMA integrity_check').all().map((r) => r.integrity_check);
ok('PRAGMA integrity_check = ok', integrity.length === 1 && integrity[0] === 'ok', integrity.join(','));

const fk = db.prepare('PRAGMA foreign_keys').get();
ok('PRAGMA foreign_keys = 1', fk.foreign_keys === 1, 'actual ' + fk.foreign_keys);

const indexes = db.prepare("SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'").all().map((r) => r.name);
for (const must of ['idx_plan_item_date', 'idx_plan_item_date_status', 'idx_todo_due_date', 'idx_habit_checkin_date', 'idx_oplog_lamport', 'idx_oplog_synced']) {
  ok('index ' + must + ' exists', indexes.includes(must));
}

expectOk('a valid habit row is accepted', () => db.prepare('INSERT INTO habit (id,name,type,schedule_type,start_date,created_at,updated_at,origin_device_id,rev) VALUES (?,?,?,?,?,?,?,?,?)').run('h1', 'water', 'count', 'daily', '2026-01-01', NOW, NOW, DEV, 1));
expectFail('plan_item.quadrant = Q9 is rejected', () => db.prepare('INSERT INTO plan_item (id,date,title,quadrant,created_at,updated_at,origin_device_id,rev) VALUES (?,?,?,?,?,?,?,?)').run('p1', '2026-01-01', 'x', 'Q9', NOW, NOW, DEV, 1));
expectFail('day_log.mood_1 = 11 is rejected', () => db.prepare('INSERT INTO day_log (id,date,mood_1,created_at,updated_at,origin_device_id,rev) VALUES (?,?,?,?,?,?,?)').run('d1', '2026-01-01', 11, NOW, NOW, DEV, 1));
expectFail('habit.type = crazy is rejected', () => db.prepare('INSERT INTO habit (id,name,type,schedule_type,start_date,created_at,updated_at,origin_device_id,rev) VALUES (?,?,?,?,?,?,?,?,?)').run('h2', 'x', 'crazy', 'daily', '2026-01-01', NOW, NOW, DEV, 1));
expectFail('a check-in of an unknown habit is rejected (FK)', () => db.prepare('INSERT INTO habit_checkin (id,habit_id,date,status,created_at,updated_at,origin_device_id,rev) VALUES (?,?,?,?,?,?,?,?)').run('hc1', 'no-such-habit', '2026-01-01', 'done', NOW, NOW, DEV, 1));

db.close();
console.log('  checks=' + checks + ' failed=' + failures);
process.exit(failures === 0 ? 0 : 1);
'@

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('actlog_g3_' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $tempDir -Force)
$helperPath = Join-Path $tempDir 'g3_migration_helper.mjs'
$brokenPath = Join-Path $tempDir 'schema_v1_broken.sql'
[System.IO.File]::WriteAllText($helperPath, $helperSource, (New-Object System.Text.UTF8Encoding($false)))

try {
    Write-Host '[g3] step 2/4: empty database -> v1 migration smoke test'
    $smoke = Invoke-Tool -Exe $node -ToolArgs @($helperPath, 'check', '--schema', $SchemaPath) -WorkingDirectory $RepoRoot
    if ($smoke.ExitCode -ne 0) {
        Write-Tail -Output $smoke.Output -Title '[g3] FAILED: the migration smoke test failed'
        $failures += 'migration smoke test failed'
    }
    else {
        Write-Host ('[g3]   OK: ' + (($smoke.Output -split "`r?`n" | Where-Object { $_ -match 'checks=' }) -join ''))
    }

    Write-Host '[g3] step 3/4: bad fixture self test'
    $badFixture = Join-Path (Join-Path (Join-Path (Join-Path $RepoRoot 'tools') 'gates') 'bad-fixtures') 'self_test.mjs'
    if ($SkipBadFixtureSelfTest) {
        Write-Host '[g3]   SKIP: -SkipBadFixtureSelfTest'
    }
    elseif (-not (Test-Path -LiteralPath $badFixture)) {
        Write-Err ('[g3] WARN: bad fixture self test not found: ' + $badFixture)
    }
    else {
        $selfTest = Invoke-Tool -Exe $node -ToolArgs @($badFixture) -WorkingDirectory $RepoRoot
        if ($selfTest.ExitCode -ne 0) {
            Write-Tail -Output $selfTest.Output -Title '[g3] FAILED: the bad fixture self test failed'
            $failures += 'bad fixture self test failed'
        }
        else {
            Write-Host '[g3]   OK: the bad fixtures really do break the constraints'
        }
    }

    Write-Host '[g3] step 4/4: tooth test - the gate must fail on a broken schema'
    if ($SkipToothTest) {
        Write-Host '[g3]   SKIP: -SkipToothTest'
    }
    else {
        $makeBroken = Invoke-Tool -Exe $node -ToolArgs @($helperPath, 'make-broken', '--schema', $SchemaPath, '--out', $brokenPath) -WorkingDirectory $RepoRoot
        if ($makeBroken.ExitCode -ne 0) {
            Write-Tail -Output $makeBroken.Output -Title '[g3] FAILED: could not build the broken schema fixture'
            $failures += 'could not build the broken schema fixture'
        }
        else {
            $onBroken = Invoke-Tool -Exe $node -ToolArgs @($helperPath, 'check', '--schema', $brokenPath) -WorkingDirectory $RepoRoot
            if ($onBroken.ExitCode -eq 0) {
                Write-Err '[g3] FAILED: the smoke test PASSED on the broken schema - this gate has no teeth.'
                Write-Err '[g3]   the broken schema had every CHECK constraint neutralised to CHECK (1=1);'
                Write-Err '[g3]   the gate must reject bad data such as quadrant = Q9.'
                $failures += 'the gate passed on a deliberately broken schema (toothless gate)'
            }
            else {
                Write-Host '[g3]   OK: the gate correctly failed on the broken schema'
                foreach ($line in (($onBroken.Output -split "`r?`n") | Where-Object { $_ -match '^\s*FAIL' })) {
                    Write-Host ('[g3]   ' + $line.Trim())
                }
            }
        }
    }
}
finally {
    try {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch { }
}

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if ($failures.Count -gt 0) {
    Write-Err '[g3] RESULT: FAIL'
    foreach ($failure in $failures) {
        Write-Err ('[g3]   - ' + $failure)
    }
    Write-Err '[g3] fix the lines above, then re-run: pwsh -File tools/gates/g3_migration.ps1'
    exit 1
}

Write-Host '[g3] RESULT: PASS'
exit 0
