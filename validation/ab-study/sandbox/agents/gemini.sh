#!/usr/bin/env bash
# Gemini CLI launcher for the A/B study. Prompt arrives on stdin.
#  - `-p ""`: headless mode without appending any text to the stdin prompt
#    (Gemini CLI appends -p's value to stdin; without -p it goes interactive).
#  - GEMINI_CLI_TRUST_WORKSPACE: a fresh fixture directory is untrusted, and in
#    an untrusted folder Gemini CLI silently downgrades --yolo to "default"
#    approval, so every tool call would be refused and the agent would answer
#    without reading -- tool deprivation masquerading as a behaviour.
export GEMINI_CLI_TRUST_WORKSPACE=true
exec gemini -p "" -o stream-json -y -m "${GEMINI_MODEL:?GEMINI_MODEL not set}"
