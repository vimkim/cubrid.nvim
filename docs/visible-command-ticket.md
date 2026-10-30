# N642. Visible CSQL command entry

The user reports that masking the whole CSQL command makes connection entry difficult. Show the command and retain a separate masked password prompt, while preserving history privacy and cancellation.

Baseline is 5ee3b019ff1dfda5c28b04fb7ac7101115fa41e3. Work in /home/vimkim/gh/cubrid.nvim-visible-command on fix/visible-csql-command; destination is main. The selected dispatch is /tmp/cubrid-visible-command-X42si2/contract.md, based on two independently run native prototypes. Read AGENTS.md and docs/spec.md before implementation. Core main is a read-only dependency.

Use native input with scoped capture-and-clear before history insertion for command text. Retain inputsecret for the password. Preserve client/generation guards, unrelated and duplicate prior history, inline-password compatibility and cancellation. Keep CSQL parsing in the central exporter.

Use native public-interface TDD for visible command text, masked password, history preservation, cancellation and the existing connection flow. Update current English/Korean README/help and record exact acceptance evidence in docs/acceptance.md with a focused report if needed. All task changes require local commits before review. Root owns work item642 and main integration approval. No publication, global installation or deployment is authorized yet.
