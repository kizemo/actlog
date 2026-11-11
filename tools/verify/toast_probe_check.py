#!/usr/bin/env python3
"""actlog P1 section 16.5 - Windows toast visibility check.

Reads the Windows notification database (wpndatabase.db) read-only and answers
one question: did the probe toast actually reach the Windows notification
platform (i.e. is it in notification center history)?

Judgement is double:
  * a row count delta against a pre-probe baseline, and
  * an exact marker string inside the stored XML payload.

Also locates the report file the app writes next to its database. The app's data
dir moved from %APPDATA%\\com.practiclog\\practilog to <exe dir>\\userdata, and
the product was renamed from PractiLog to actlog on top of that, so the search
covers the current names first and every legacy name afterwards (see
tools/verify/data_location.ps1 for the same order).
"""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path

DEFAULT_MARKER = "P1-TOAST-PROBE-20261107"

# Current report file name first, legacy one second.
PROBE_REPORT_NAMES = ("actlog_toast_probe.log", "practilog_toast_probe.log")

USERDATA_DIR_NAME = "userdata"
# Current data dirs first, legacy ones after.
CURRENT_APPDATA_SUBPATH = os.path.join("com.actlog", "actlog")
LEGACY_APPDATA_SUBPATH = os.path.join("com.practiclog", "practilog")
CURRENT_PROGRAMDATA_SUBPATH = "actlog"
LEGACY_PROGRAMDATA_SUBPATH = "practilog"
CURRENT_FALLBACK_SUBPATH = os.path.join("com.actlog", "actlog-fallback")
LEGACY_FALLBACK_SUBPATH = os.path.join("com.practiclog", "practilog-fallback")
# Tried when the caller does not say which build it is checking, so the default
# invocation still finds the report after the data-dir move.
DEFAULT_EXE_CANDIDATES = (
    r"F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release\actlog.exe",
    r"F:\soft\00selfmade\practilog\apps\desktop\build\windows\x64\runner\Release\practilog.exe",
    r"F:\soft\00selfmade\practilog\release\actlog.exe",
    r"F:\soft\00selfmade\practilog\release\practilog.exe",
)


def userdata_dir_for_exe(exe_path: str) -> str:
    """Return <dir of the exe>\\userdata, the post-migration data dir.

    Deliberately NOT <exe dir>\\data: that is Flutter's own asset directory and
    must never be treated as application data.
    """
    if not exe_path:
        return ""
    exe_dir = os.path.dirname(os.path.abspath(exe_path))
    if not exe_dir:
        return ""
    return os.path.join(exe_dir, USERDATA_DIR_NAME)


def data_dir_candidates(exe_path: str = "", extra=()) -> list:
    """Ordered, de-duplicated data dirs the probe report may live in.

    Mirrors tools/verify/data_location.ps1 and apps/desktop/lib/src/app_paths.dart:
    pinned env, then the new <exe dir>\\userdata, then %PROGRAMDATA%, then the
    %LOCALAPPDATA% fallback, then %APPDATA% last. Every entry has a current and
    a legacy spelling; the current one is always probed first.
    """
    cands: list = []

    def add(path: str) -> None:
        if path and path not in cands:
            cands.append(path)

    add(os.environ.get("ACTLOG_DATA_DIR", ""))
    add(os.environ.get("PRACTILOG_DATA_DIR", ""))
    for d in extra or ():
        add(d)
    add(userdata_dir_for_exe(exe_path))
    for exe in DEFAULT_EXE_CANDIDATES:
        add(userdata_dir_for_exe(exe))
    add(os.path.join(os.environ.get("PROGRAMDATA", ""), CURRENT_PROGRAMDATA_SUBPATH))
    add(os.path.join(os.environ.get("PROGRAMDATA", ""), LEGACY_PROGRAMDATA_SUBPATH))
    add(os.path.join(os.environ.get("LOCALAPPDATA", ""), CURRENT_FALLBACK_SUBPATH))
    add(os.path.join(os.environ.get("LOCALAPPDATA", ""), LEGACY_FALLBACK_SUBPATH))
    # Legacy %APPDATA% comes last: the app no longer writes there (it is only the
    # migration source), but every report written before the migration is there.
    add(os.path.join(os.environ.get("APPDATA", ""), CURRENT_APPDATA_SUBPATH))
    add(os.path.join(os.environ.get("APPDATA", ""), LEGACY_APPDATA_SUBPATH))
    return [c for c in cands if c]


def notification_db() -> Path:
    local = os.environ.get("LOCALAPPDATA", "")
    return Path(local) / "Microsoft" / "Windows" / "Notifications" / "wpndatabase.db"


def query(marker: str, scan: int = 300) -> dict:
    db_path = notification_db()
    result: dict = {"db": str(db_path), "db_exists": db_path.exists()}
    if not db_path.exists():
        return result
    uri = "file:" + db_path.as_posix() + "?mode=ro"
    con = sqlite3.connect(uri, uri=True, timeout=15)
    try:
        result["total"] = con.execute('SELECT COUNT(*) FROM "Notification"').fetchone()[0]
        rows = con.execute(
            'SELECT "Order", Id, Tag, Type, Payload FROM "Notification" '
            'ORDER BY "Order" DESC LIMIT ?',
            (scan,),
        ).fetchall()
        hits = []
        for order, nid, tag, ntype, payload in rows:
            if payload is None:
                continue
            if isinstance(payload, (bytes, bytearray)):
                payload = payload.decode("utf-8", "replace")
            if marker in payload:
                hits.append(
                    {
                        "order": order,
                        "id": nid,
                        "tag": tag,
                        "type": ntype,
                        "payload": payload[:900],
                    }
                )
        result["scanned"] = len(rows)
        result["marker_hits"] = len(hits)
        result["hits"] = hits[:3]
    finally:
        con.close()
    return result


def find_probe_report(max_depth: int = 2, extra_roots=()) -> list:
    """Locate the app-side probe report across current and legacy data dirs.

    extra_roots are checked first (they are exact candidate dirs, so the report
    sits directly inside them); the historical APPDATA/LOCALAPPDATA sweeps stay
    as a fallback for pre-migration runs.
    """
    found = []
    seen = set()

    def push(path: Path) -> None:
        key = str(path)
        if key not in seen:
            seen.add(key)
            found.append(key)

    for root in list(extra_roots or ()):
        if root and Path(root).is_dir():
            for name in PROBE_REPORT_NAMES:
                candidate = Path(root) / name
                if candidate.is_file():
                    push(candidate)
    for root in [os.environ.get("APPDATA", ""), os.environ.get("LOCALAPPDATA", "")]:
        if not root:
            continue
        base = Path(root)
        if not base.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            depth = len(Path(dirpath).relative_to(base).parts)
            if depth >= max_depth:
                dirnames[:] = []
            for name in PROBE_REPORT_NAMES:
                if name in filenames:
                    push(Path(dirpath) / name)
    return found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--marker", default=DEFAULT_MARKER)
    parser.add_argument("--scan", type=int, default=300)
    parser.add_argument("--report", default=None, help="evidence file to write")
    parser.add_argument(
        "--data-dir",
        action="append",
        default=[],
        help="exact actlog data dir to search first (repeatable)",
    )
    parser.add_argument(
        "--exe",
        default="",
        help="path of actlog.exe; its sibling userdata dir is searched as a data dir",
    )
    args = parser.parse_args()

    res = query(args.marker, scan=args.scan)
    data_dirs = data_dir_candidates(args.exe, tuple(args.data_dir))
    res["data_dirs"] = data_dirs
    reports = find_probe_report(extra_roots=data_dirs)
    res["probe_reports"] = reports
    texts = []
    for path in reports:
        try:
            texts.append(Path(path).read_text(encoding="utf-8", errors="replace"))
        except Exception as exc:  # pragma: no cover - diagnostics only
            texts.append("(read failed: %s)" % exc)
    res["probe_report_text"] = texts

    hits = res.get("marker_hits", 0)
    res["verdict"] = "PASS" if hits > 0 else "FAIL"

    text = json.dumps(res, ensure_ascii=False, indent=2)
    print(text)
    if args.report:
        out = Path(args.report)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    return 0 if hits > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
