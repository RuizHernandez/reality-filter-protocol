# Backend: DeepSeek through the Claude Code harness, via DeepSeek's documented
# Anthropic-compatible endpoint (api-docs.deepseek.com/guides/anthropic_api).
# Sourced in a subshell by lib/docker-common.sh. Defines the model label, the
# environment variable NAMES passed into the container (values never appear on
# a command line), the command run inside it, and which secrets it carries.
: "${DEEPSEEK_API_KEY:?set DEEPSEEK_API_KEY in secrets.env}"
: "${DEEPSEEK_MODEL:?set DEEPSEEK_MODEL in secrets.env}"
BACKEND_MODEL="deepseek:$DEEPSEEK_MODEL"
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
export ANTHROPIC_MODEL="$DEEPSEEK_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$DEEPSEEK_MODEL"
BACKEND_ENV=(ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL)
BACKEND_CMD=(claude -p --output-format stream-json --verbose --permission-mode bypassPermissions --model "$DEEPSEEK_MODEL")
