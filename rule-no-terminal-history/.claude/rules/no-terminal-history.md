---
description: Prefix all shell commands with a leading space to exclude them from zsh history
---

Always prefix shell commands with a leading space character when running them via terminal tools.

zsh with HIST_IGNORE_SPACE set skips history recording for commands that begin with a space.

Example: ` mvn verify` instead of `mvn verify`.
