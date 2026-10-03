# Client tests (Lockedin-Huawei)

Test code for the client app lives here, apart from the app in `src/`. The environment's own tests live in the
submodule (`suggested-host-venv/tests/README.md`).

```bash
python3 -m unittest discover -s tests -t .      # contract tests: client interfaces vs the real harness server (mocked planner)
./dev check                                      # lint + build of the app itself
```

- `tests/contract/test_harness_contract.py` starts the real harness API from the submodule with the planner mocked
  (no tokens, no emulator), drives the same calls the app makes, and checks that every **required** field of each
  ArkTS interface in `src/.../model/HarnessClient.ets` is present in the server's JSON. Renaming a server field or
  adding a required client field without the server fails this test.
- Add a scenario: call the endpoint the app uses, then `self.assertMatches("<InterfaceName>", payload)`.
- On-device UI checks are driven with `./dev ui dump` / `./dev ui click` against an emulator (see the submodule's
  AGENTS.md); they are intentionally not automated here yet.
