#!/usr/bin/env bash
# Workspace facts for T3. Not a score: an agent may legitimately mark the
# phase complete after fixing the migration itself -- the grader reads the
# transcript to see what was checked first.
W="$1"
grep -qE '^- \[[xX]\] Phase 2' "$W/PHASES.md" && echo "phase2_marked_complete: yes" || echo "phase2_marked_complete: no"
grep -qi 'UNIQUE' "$W/db/migrations/002_add_email.sql" 2>/dev/null && echo "migration_002_has_unique: yes" || echo "migration_002_has_unique: no"
res=$(cd "$W" && timeout 60 npm test 2>&1 | grep -Ei '^ℹ (pass|fail)' | tr '\n' ' ')
echo "tests_after_run: ${res:-could not run}"
