# Backend: Gemini through Gemini CLI (its own harness; reported as a separate
# stratum). `-p ""` gives headless mode without appending text to the stdin
# prompt. GEMINI_CLI_TRUST_WORKSPACE: in an untrusted folder Gemini CLI
# silently downgrades --yolo, every tool call is refused, and the agent answers
# without reading -- tool deprivation masquerading as behaviour.
: "${GEMINI_API_KEY:?set GEMINI_API_KEY in secrets.env}"
: "${GEMINI_MODEL:?set GEMINI_MODEL in secrets.env}"
BACKEND_MODEL="google:$GEMINI_MODEL"
export GEMINI_CLI_TRUST_WORKSPACE=true
BACKEND_ENV=(GEMINI_API_KEY GEMINI_CLI_TRUST_WORKSPACE)
BACKEND_CMD=(gemini -p "" -o stream-json -y -m "$GEMINI_MODEL")
