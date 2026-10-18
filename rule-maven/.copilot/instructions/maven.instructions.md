---
description: 'Maven build conventions: -f for module targeting, -B -ntp quiet output, narrowest goal, build cache disabled.'
applyTo: '**/pom.xml, **/*.java, **/*.kt, **/*.kts, **/*.scala, **/*.groovy'
---

# Maven Rules

Only for Maven projects (`pom.xml` present); skip for Gradle. Use `./mvnw` instead of `mvn` when it exists.

Canonical form:
```bash
mvn -B -ntp -T 1C -Dmaven.build.cache.enabled=false -f path/to/pom.xml <goal>
```

- Target modules with `-f <module>/pom.xml`, not `-pl`. With `-f`, sibling modules resolve from `~/.m2`: after changing an upstream module, `install` it first or build from the root POM.
- `-B -ntp`: plain log without colors or download progress (smaller output).
- `-T 1C` and `-fae` (report all module failures) only matter when the target POM aggregates modules.
- Build cache off so results are never served from cache after edits.
- Run the narrowest goal: `test-compile` to check types; `-Dtest=Class#method -Dsurefire.failIfNoSpecifiedTests=false` for single tests; full `verify` only before finishing.
