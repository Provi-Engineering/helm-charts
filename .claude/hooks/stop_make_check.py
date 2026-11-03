"""Claude Code Stop hook: hold the turn while `make check` fails on a tree that differs from `main`.

The hook reads the Stop event from stdin. A subagent, a directory outside this project's git repository, or a tree with
no diff against `main` ends the turn without running `make check`. Otherwise the hook reuses the recorded result for the
current tree, or runs `make check` and records it. A new failure holds the turn and hands the session the output; a
repeated stop on the same red tree ends the turn and tells the operator which gate failed. Any error ends the turn.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import signal
import subprocess  # nosec B404 # runs fixed git and make argument lists, never shell strings
import sys
from pathlib import Path
from typing import Any

STATE_NAME = "stop-make-check.json"
OUTPUT_TAIL_LINES = 200
# Below the hook's 600-second timeout in .claude/settings.json, so the hook records the result before it is killed.
MAKE_CHECK_TIMEOUT_SECONDS = 540
# Make 3.81 prints `*** [lint] Error 1`; make 4 prints `*** [Makefile:16: lint] Error 1`.
GATE_ERROR = re.compile(r"\*\*\* \[(?:[^\]]*:\s*)?([\w-]+)\] Error")


def executable(name: str) -> str:
    """Return the absolute path of `name` on PATH."""
    path = shutil.which(name)
    if path is None:
        raise RuntimeError(f"{name} is not on PATH")
    return path


def git(root: Path, *args: str) -> subprocess.CompletedProcess[bytes]:
    """Run a git command in `root` and return its completed process."""
    command = [executable("git"), *args]
    return subprocess.run(command, cwd=root, capture_output=True, check=False)  # nosec B603 # fixed argument list


def git_output(root: Path, *args: str) -> str:
    """Return a git command's stripped stdout, raising when it fails."""
    result = git(root, *args)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.decode())
    return result.stdout.decode().strip()


def common_dir(path: Path) -> Path | None:
    """Return the shared git directory of the repository containing `path`, or None outside one."""
    result = git(path, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if result.returncode != 0:
        return None
    return Path(result.stdout.decode().strip()).resolve()


def untracked_files(root: Path) -> list[str]:
    """Return the work tree's untracked, non-ignored paths, sorted."""
    output = git_output(root, "ls-files", "--others", "--exclude-standard", "-z")
    return sorted(path for path in output.split("\0") if path)


def differs_from_main(root: Path, untracked: list[str]) -> bool:
    """Return whether the work tree's tracked files differ from `main` or it holds untracked files."""
    diff = git(root, "diff", "--quiet", "main", "--")
    if diff.returncode not in (0, 1):
        raise RuntimeError(diff.stderr.decode())
    return diff.returncode == 1 or bool(untracked)


def fingerprint(root: Path, untracked: list[str]) -> str:
    """Return a SHA-256 over HEAD, the diff against HEAD, and every untracked file's path and bytes."""
    digest = hashlib.sha256()
    digest.update(git(root, "rev-parse", "HEAD").stdout)
    digest.update(git(root, "diff", "HEAD", "--binary").stdout)
    for path in untracked:
        digest.update(path.encode() + b"\0")
        file = root / path
        if file.is_file():
            digest.update(file.read_bytes())
    return digest.hexdigest()


def state_path(root: Path) -> Path:
    """Return the state file's path inside this work tree's own git directory."""
    return Path(git_output(root, "rev-parse", "--path-format=absolute", "--git-path", STATE_NAME))


def read_state(path: Path) -> dict[str, Any]:
    """Return the recorded result, or an empty record when none is readable."""
    try:
        state = json.loads(path.read_text())
    except (OSError, ValueError):
        return {}
    return state if isinstance(state, dict) else {}


def failing_gate(output: str) -> str:
    """Return the gate make names in its last error line, or `make check` when it names none."""
    matches = GATE_ERROR.findall(output)
    return matches[-1] if matches else "make check"


def run_make_check(root: Path) -> tuple[bool, str, str | None]:
    """Run `make check` in `root` and return whether it passed, its output, and the failing gate."""
    command = [executable("make"), "check"]
    # A new session puts make and its children in one process group, so a timeout kills them all.
    process = subprocess.Popen(  # nosec B603 # fixed argument list
        command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True
    )
    try:
        stdout, _ = process.communicate(timeout=MAKE_CHECK_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        stdout, _ = process.communicate()
        output = stdout.decode(errors="replace")
        return False, f"{output}\nmake check timed out after {MAKE_CHECK_TIMEOUT_SECONDS} seconds.", "timeout"
    output = stdout.decode(errors="replace")
    if process.returncode == 0:
        return True, output, None
    return False, output, failing_gate(output)


def decide(event: dict[str, Any], project_dir: Path) -> dict[str, str] | None:
    """Return the hook's JSON output for a Stop event, or None to end the turn silently."""
    if event.get("agent_id"):
        return None
    cwd = Path(event.get("cwd") or ".")
    shared = common_dir(cwd)
    if shared is None or shared != common_dir(project_dir):
        return None
    root = Path(git_output(cwd, "rev-parse", "--show-toplevel"))
    untracked = untracked_files(root)
    if not differs_from_main(root, untracked):
        return None

    tree = fingerprint(root, untracked)
    path = state_path(root)
    state = read_state(path)
    if state.get("fingerprint") == tree:
        if state.get("passed"):
            return None
        # A timeout reflects machine load, not the tree, so the next stop reruns make check instead of reusing it.
        if state.get("gate") == "timeout":
            path.unlink(missing_ok=True)
        return {
            "systemMessage": (
                f"make check is red at the {state.get('gate')} gate; the session ended its turn on an unchanged tree."
            )
        }

    passed, output, gate = run_make_check(root)
    path.write_text(json.dumps({"fingerprint": tree, "passed": passed, "gate": gate}))
    if passed:
        return None

    tail = "\n".join(output.splitlines()[-OUTPUT_TAIL_LINES:])
    return {
        "decision": "block",
        "reason": (
            f"make check failed at the {gate} gate on a tree that differs from main. Fix it before ending the turn. "
            "To park or to ask the operator, end the turn again without changing the tree.\n\n"
            f"{tail}"
        ),
    }


def main() -> None:
    """Read the Stop event from stdin and print the hook's decision; end the turn on any error."""
    try:
        output = decide(json.load(sys.stdin), Path(os.environ["CLAUDE_PROJECT_DIR"]))
    # The hook fails open: a broken hook must never trap a session in its turn.
    except Exception as error:
        print(f"stop_make_check: {error}", file=sys.stderr)
        return
    if output is not None:
        print(json.dumps(output))


if __name__ == "__main__":
    main()
