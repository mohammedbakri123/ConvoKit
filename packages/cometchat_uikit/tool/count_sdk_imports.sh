#!/usr/bin/env bash
# ConvoKit Phase 7 — SDK Import Counter & No-New-Import Gate
#
# Usage:
#   bash packages/cometchat_uikit/tool/count_sdk_imports.sh           # Print current counts
#   bash packages/cometchat_uikit/tool/count_sdk_imports.sh --check   # Print counts & fail if any new cometchat import appears
#
# Exit codes:
#   0  Success (or --check passed with zero new package:cometchat_* imports)
#   1  Gate violation (--check detected a new file or increased statement count)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PKG_DIR}/../.." && pwd)"

CHECK_MODE=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

python3 - "$REPO_ROOT" "$PKG_DIR" "$CHECK_MODE" <<'PYEOF'
import os
import re
import sys
from collections import Counter

repo_root = sys.argv[1]
pkg_dir = sys.argv[2]
check_mode = sys.argv[3] == "1"

lib_dir = os.path.join(pkg_dir, "lib")
test_dir = os.path.join(pkg_dir, "test")

# Phase 7.7 locked baseline (legacy adapters, auth gateway, SDK listeners, and legacy cometchat_ui_kit cleared: 10 -> 0; lib/ and examples/ locked at 0 package:cometchat_* imports; flutter_bloc in lib/ locked at 0)
BASELINE_MAX_ACTIVE_FILES = 0
BASELINE_MAX_ACTIVE_STATEMENTS = 0
BASELINE_MAX_RG_FILES = 0
BASELINE_MAX_RG_LINES = 0
BASELINE_ALLOWED_ACTIVE_LIB_FILES = set()

IMP_RE = re.compile(r"""^\s*(import|export)\s+['"]package:cometchat_[^'"]+['"]""", re.M)
ANY_COMETCHAT_RE = re.compile(r"package:cometchat_")
SDK_RE = re.compile(r"package:cometchat_sdk")
CARDS_RE = re.compile(r"package:cometchat_cards")
BLOC_IMP_RE = re.compile(r"""^\s*(import|export)\s+['"]package:flutter_bloc/""", re.M)
EXC_TOKEN_RE = re.compile(r"\bCometChatException\b")
EXC_CATCH_RE = re.compile(r"\bon\s+CometChatException\b")
ADAPTER_RE = re.compile(r"src/adapters/|chat_auth_gateway\.dart|chat_sdk_listeners\.dart")


def walk_files(root, ext=None):
    for dp, _, fns in os.walk(root):
        for fn in sorted(fns):
            if ext is None or fn.endswith(ext):
                yield os.path.join(dp, fn)


lib_active_files = set()
lib_active_statements = 0
lib_rg_files = set()
lib_rg_lines = 0
lib_sdk_files = 0
lib_cards_files = 0
lib_by_area = Counter()
lib_bloc_import_files = 0
lib_bloc_mention_files = 0
lib_exc_tokens = 0
lib_exc_lines = 0
lib_exc_files = 0
lib_exc_catches = 0
lib_adapter_files = 0

for p in walk_files(lib_dir):
    txt = open(p, encoding="utf-8", errors="ignore").read()
    if "flutter_bloc" in txt:
        lib_bloc_mention_files += 1
    if not p.endswith(".dart"):
        continue
    rel = os.path.relpath(p, lib_dir).replace(os.sep, "/")
    imps = IMP_RE.findall(txt)
    if imps:
        lib_active_files.add(rel)
        lib_active_statements += len(imps)
    if ANY_COMETCHAT_RE.search(txt):
        lib_rg_files.add(rel)
        lib_rg_lines += sum(1 for ln in txt.splitlines() if ANY_COMETCHAT_RE.search(ln))
        if rel.startswith("chat_ui/src/"):
            lib_by_area["chat_ui/src/"] += 1
        elif rel.startswith("shared_ui/"):
            lib_by_area["shared_ui/"] += 1
        elif rel.startswith("src/adapters/"):
            lib_by_area["src/adapters/"] += 1
        else:
            lib_by_area["src/ (other)"] += 1
    if SDK_RE.search(txt):
        lib_sdk_files += 1
    if CARDS_RE.search(txt):
        lib_cards_files += 1
    if BLOC_IMP_RE.search(txt):
        lib_bloc_import_files += 1
    exc_toks = EXC_TOKEN_RE.findall(txt)
    if exc_toks:
        lib_exc_tokens += len(exc_toks)
        lib_exc_files += 1
    lib_exc_lines += sum(1 for ln in txt.splitlines() if "CometChatException" in ln)
    lib_exc_catches += len(EXC_CATCH_RE.findall(txt))
    if ADAPTER_RE.search(txt):
        lib_adapter_files += 1

test_import_files = 0
test_any_files = 0
for p in walk_files(test_dir, ext=".dart"):
    txt = open(p, encoding="utf-8", errors="ignore").read()
    if IMP_RE.search(txt):
        test_import_files += 1
    if ANY_COMETCHAT_RE.search(txt):
        test_any_files += 1

print("=== ConvoKit Phase 7 SDK Import Count ===")
print(f"lib/ files with active package:cometchat_* import/export : {len(lib_active_files)} (baseline max: {BASELINE_MAX_ACTIVE_FILES})")
print(f"lib/ active package:cometchat_* import/export statements : {lib_active_statements} (baseline max: {BASELINE_MAX_ACTIVE_STATEMENTS})")
print(f"lib/ rg 'package:cometchat_' files / lines               : {len(lib_rg_files)} files / {lib_rg_lines} lines (baseline max: {BASELINE_MAX_RG_FILES} / {BASELINE_MAX_RG_LINES})")
print(f"  - package:cometchat_sdk files (rg)                     : {lib_sdk_files}")
print(f"  - package:cometchat_cards files (rg)                   : {lib_cards_files}")
print(f"  - chat_ui/src/                                         : {lib_by_area['chat_ui/src/']}")
print(f"  - shared_ui/                                           : {lib_by_area['shared_ui/']}")
print(f"  - src/adapters/                                        : {lib_by_area['src/adapters/']}")
print(f"  - src/ (other)                                         : {lib_by_area['src/ (other)']}")
print(f"test/ files actively importing package:cometchat_*       : {test_import_files}")
print(f"test/ total files matching package:cometchat_ (incl. guardrail tests): {test_any_files}")
print(f"lib/ files importing package:flutter_bloc/               : {lib_bloc_import_files}")
print(f"lib/ total files mentioning flutter_bloc (incl. docs/comments): {lib_bloc_mention_files}")
print(f"lib/ CometChatException tokens (files) / lines / on-catch: {lib_exc_tokens} ({lib_exc_files} files) / {lib_exc_lines} lines / {lib_exc_catches} on-catch")
print(f"lib/ files referencing src/adapters/ or auth/listeners   : {lib_adapter_files}")

if check_mode:
    violations = []
    new_files = sorted(lib_active_files - BASELINE_ALLOWED_ACTIVE_LIB_FILES)
    if new_files:
        violations.append(
            f"NEW package:cometchat_* import(s) detected in {len(new_files)} non-baseline file(s):\n"
            + "\n".join(f"  - {f}" for f in new_files)
        )
    if len(lib_active_files) > BASELINE_MAX_ACTIVE_FILES:
        violations.append(
            f"Total lib/ files importing package:cometchat_* ({len(lib_active_files)}) "
            f"exceeds locked baseline ({BASELINE_MAX_ACTIVE_FILES})."
        )
    if lib_active_statements > BASELINE_MAX_ACTIVE_STATEMENTS:
        violations.append(
            f"Total lib/ package:cometchat_* import/export statements ({lib_active_statements}) "
            f"exceeds locked baseline ({BASELINE_MAX_ACTIVE_STATEMENTS})."
        )
    if len(lib_rg_files) > BASELINE_MAX_RG_FILES or lib_rg_lines > BASELINE_MAX_RG_LINES:
        violations.append(
            f"Total rg 'package:cometchat_' matches ({len(lib_rg_files)} files / {lib_rg_lines} lines) "
            f"exceeds locked baseline ({BASELINE_MAX_RG_FILES} files / {BASELINE_MAX_RG_LINES} lines)."
        )

    if violations:
        print("\n[FAIL] Phase 7 CometChat import gate failed:", file=sys.stderr)
        for v in violations:
            print(v, file=sys.stderr)
        sys.exit(1)
    else:
        print("\n[PASS] Phase 7 CometChat import gate passed (zero new package:cometchat_* imports).")
PYEOF
