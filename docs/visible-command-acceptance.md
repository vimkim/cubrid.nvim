# N642 acceptance

The command prompt displays editable CSQL text. The password prompt masks its input. An inline password remains part of the visible command, so users should prefer the separate password prompt.

The native PTY test first failed on baseline `5ee3b019ff1dfda5c28b04fb7ac7101115fa41e3` because the command was not visible. It passed after the change. The test preserves indexed input history containing the same command and unrelated entries, preserves Ex history, and covers accepted and cancelled command and password prompts. The existing schema flow covers acquisition, refresh, disconnect, and redaction. The extracted portable suite exercises the packaged plugin with an isolated server, exporter, and controlled CSQL fixture.

Evidence paths and limitations are recorded in [acceptance.md](acceptance.md#visible-csql-command-entry-n642).
