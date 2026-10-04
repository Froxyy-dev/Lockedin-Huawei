"""Contract test: the client's ArkTS interfaces (src/.../model/HarnessClient.ets) must match what the harness server
actually returns. Runs the real harness server against mocks (no tokens, no emulator) and compares field by field.

Catches the class of bug we hit by hand: a field the client expects that the server never sends, or renamed keys.
Run from this repo:  python3 -m unittest discover -s tests -t .
Needs the environment submodule checked out (suggested-host-venv/). Skips if it is missing.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV = ROOT / "suggested-host-venv"
CLIENT = ROOT / "src" / "entry" / "src" / "main" / "ets" / "model" / "HarnessClient.ets"
TOKEN = "contract-token"


def interfaces(ets: str) -> dict[str, dict[str, bool]]:
    """{InterfaceName: {field: required}} parsed from ArkTS `interface` blocks."""
    out = {}
    for m in re.finditer(r"(?:export )?interface (\w+)\s*\{(.*?)\n\}", ets, re.S):
        fields = {}
        for line in m.group(2).splitlines():
            fm = re.match(r"\s*(\w+)(\?)?\s*:", line)
            if fm:
                fields[fm.group(1)] = fm.group(2) is None
        out[m.group(1)] = fields
    return out


def _free_port():
    import socket
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0)); return s.getsockname()[1]


@unittest.skipIf(not (ENV / "harness" / "api.py").exists(), "environment submodule not checked out")
class HarnessContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ENV))
        from planner.tests.mocks.openai_server import MockOpenAI
        cls.mock = MockOpenAI().start()
        cls.tmp = tempfile.TemporaryDirectory(prefix="hos-contract-")
        cls.port = _free_port()
        env = dict(os.environ, HOS_REPO=str(ENV), HARNESS_ROOT=cls.tmp.name, HARNESS_PORT=str(cls.port),
                   HARNESS_BIND="127.0.0.1", HARNESS_CLIENTS=f"{TOKEN}=contract", BOT_TOKEN="", **cls.mock.env())
        env.pop("HOS_APP", None)
        cls.proc = subprocess.Popen(["python3", str(ENV / "harness" / "api.py")], cwd=str(ENV), env=env,
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            try:
                cls.call("GET", "/me"); break
            except Exception:
                time.sleep(0.2)
        cls.ifaces = interfaces(CLIENT.read_text())

    @classmethod
    def tearDownClass(cls):
        cls.proc.terminate(); cls.proc.wait(timeout=10); cls.mock.stop(); cls.tmp.cleanup()

    @classmethod
    def call(cls, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(f"http://127.0.0.1:{cls.port}{path}", data=data, method=method,
                                     headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read())

    def wait_planned(self, pid: str, n: int) -> dict:
        """Draft/refine return at once in state `planning`; poll until the mocked planner has answered."""
        for _ in range(100):
            rev = self.call("GET", f"/projects/{pid}/revisions/{n}")
            if rev["state"] in ("drafted", "plan_failed"):
                return rev
            time.sleep(0.1)
        self.fail("planning did not finish")

    def assertMatches(self, iface: str, payload: dict):
        fields = self.ifaces[iface]
        missing = [f for f, required in fields.items() if required and f not in payload]
        self.assertEqual(missing, [], f"{iface}: server response lacks required fields {missing}; got {sorted(payload)}")

    def test_client_interfaces_match_server_json(self):
        self.assertMatches("Me", self.call("GET", "/me"))
        project = self.call("POST", "/projects", {"name": "Contract"})
        self.assertMatches("ProjectDetail", self.call("GET", f"/projects/{project['id']}"))
        for p in self.call("GET", "/projects"):
            self.assertMatches("Project", p)
        rev = self.call("POST", f"/projects/{project['id']}/revisions", {"text": "People forget to water plants", "effort": "fast"})
        self.assertMatches("Revision", rev); self.assertMatches("RevisionSummaryInfo", rev["summary"])
        self.assertEqual(rev["effort"], "fast", "the slider's level comes back with the revision")
        self.assertEqual(self.wait_planned(project["id"], 1)["state"], "drafted")
        rev2 = self.call("POST", f"/projects/{project['id']}/revisions/1/refine", {"feedback": "simpler", "effort": "high"})
        self.assertMatches("Revision", rev2); self.assertEqual(rev2["effort"], "high")
        self.wait_planned(project["id"], 2)
        feed = self.call("GET", f"/projects/{project['id']}/revisions/2/progress")
        self.assertEqual([e["kind"] for e in feed["events"]], ["considering", "rewriting", "planned"])
        detail = self.call("GET", f"/projects/{project['id']}")
        for r in detail["revisions"]:
            self.assertMatches("RevisionSummary", r)
        self.assertMatches("Revision", self.call("GET", f"/projects/{project['id']}/revisions/2"))
        acc = self.call("POST", f"/projects/{project['id']}/revisions/2/accept", {"effort": "medium"})   # no bot configured -> accepted
        self.assertMatches("AcceptResult", acc); self.assertEqual(acc["effort"], "medium")
        self.assertMatches("DiffResult", self.call("GET", f"/projects/{project['id']}/revisions/2/diff"))
        feed = self.call("GET", f"/projects/{project['id']}/revisions/2/progress")
        self.assertMatches("ProgressFeed", feed)
        self.assertEqual(feed["events"], [], "no bot configured: an accepted revision has an empty feed")
        sample = {"t": "2026-10-04T00:00:00+00:00", "last": "2026-10-04T00:00:00+00:00", "kind": "coding",
                  "text": "Writing the app", "count": 2, "problem": False}       # shape served by bot/progress.py fold()
        self.assertMatches("ProgressEvent", sample)

    def test_post_without_body_is_accepted_by_server(self):
        """The client once sent an empty body on accept; the server must tolerate '' and '{}'."""
        project = self.call("POST", "/projects", {"name": "Empty body"})
        self.call("POST", f"/projects/{project['id']}/revisions", {"text": "idea"})
        self.wait_planned(project["id"], 1)
        req = urllib.request.Request(f"http://127.0.0.1:{self.port}/projects/{project['id']}/revisions/1/accept",
                                     data=b"", method="POST", headers={"Authorization": f"Bearer {TOKEN}"})
        with urllib.request.urlopen(req, timeout=30) as r:
            self.assertEqual(json.loads(r.read())["state"], "accepted")


if __name__ == "__main__":
    unittest.main()
