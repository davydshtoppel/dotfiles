---
description: Maven build conventions: -f for module targeting, -T 1C parallelism, build cache disabled
paths:
  - "**/pom.xml"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.kts"
  - "**/*.scala"
  - "**/*.groovy"
---

# Maven Build Rules

Apply these conventions when writing or suggesting Maven commands.

## Module Targeting
- Always use `-f <path/to/pom.xml>` to target a specific module — never `-pl <module-name>`
- `-pl` relies on the reactor; a module may be silently excluded when the activating profile is absent
- Example: `mvn -f services/payment/pom.xml verify` instead of `mvn -pl services/payment verify`

## Parallelism
- Always add `-T 1C` to all multi-step goals (`compile`, `test`, `package`, `verify`, `install`)
- `1C` means one thread per available CPU core, which scales automatically across machines
- Example: `mvn -T 1C -f path/to/pom.xml verify`

## Disable Build Cache
- Add `-Dmaven.build.cache.enabled=false` to disable the Maven Build Cache Extension
- This guarantees a cache-independent result suitable for CI and troubleshooting

## Output Quality
- Add `--no-transfer-progress` (`-ntp`) to suppress noisy download progress bars
- Use `-fae` (fail at end) when running tests across multiple modules — reports all failures rather than aborting on the first

## Canonical Form
```bash
mvn -T 1C -ntp -Dmaven.build.cache.enabled=false -f path/to/pom.xml <goal>
```