#!/bin/sh
# Creates a new project directory, initialises git, and applies all Setup configs.
#
# Usage:
#   ./new-project.sh --name my-api --stack node [--base /path] [--github] [--visibility private]
#
# Requires: git, jq. Optional: gh (GitHub CLI)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAME=""
STACK=""
BASE_PATH="$(pwd)"
GITHUB_REPO=0
VISIBILITY="private"

# ── Argument parsing ──────────────────────────────────────────────────────────

while [ "$#" -gt 0 ]; do
  case "$1" in
    --name)       NAME="$2";       shift 2 ;;
    --stack)      STACK="$2";      shift 2 ;;
    --base)       BASE_PATH="$2";  shift 2 ;;
    --github)     GITHUB_REPO=1;   shift   ;;
    --visibility) VISIBILITY="$2"; shift 2 ;;
    *) printf "Unknown argument: %s\n" "$1" >&2; exit 1 ;;
  esac
done

# ── Pre-flight ────────────────────────────────────────────────────────────────

if [ -z "$NAME" ];  then printf "Error: --name is required\n"  >&2; exit 1; fi
if [ -z "$STACK" ]; then printf "Error: --stack is required\n" >&2; exit 1; fi

PROJECT_PATH="$BASE_PATH/$NAME"

if [ -d "$PROJECT_PATH" ]; then
  printf "Error: Directory already exists: %s\n" "$PROJECT_PATH" >&2; exit 1
fi

printf "\n"
printf "  Creating project : %s\n" "$NAME"
printf "  Stack            : %s\n" "$STACK"
printf "  Location         : %s\n\n" "$PROJECT_PATH"

# ── 1. Create directory & git init ───────────────────────────────────────────

mkdir -p "$PROJECT_PATH"
git -C "$PROJECT_PATH" init -q
git -C "$PROJECT_PATH" checkout -q -b main
printf "  ✔ git init (branch: main)\n"

# ── 2. Apply Setup configs ────────────────────────────────────────────────────

printf "\n"
sh "$SCRIPT_DIR/apply.sh" --target "$PROJECT_PATH" --stack "$STACK"

# ── 3. Create .gitignore ──────────────────────────────────────────────────────

cat > "$PROJECT_PATH/.gitignore" << 'EOF'
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/*.log

# Secrets
.env
.env.*
!.env.example
EOF

case "$STACK" in
  node)
    cat >> "$PROJECT_PATH/.gitignore" << 'EOF'
# Node
node_modules/
dist/
build/
.next/
coverage/
*.log
EOF
    ;;
  python)
    cat >> "$PROJECT_PATH/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
.venv/
dist/
build/
*.egg-info/
.pytest_cache/
.ruff_cache/
htmlcov/
EOF
    ;;
  dotnet)
    cat >> "$PROJECT_PATH/.gitignore" << 'EOF'
# .NET
bin/
obj/
.vs/
TestResults/
EOF
    ;;
esac

printf "  ✔ .gitignore created\n"

# ── 4. Create README ──────────────────────────────────────────────────────────

cat > "$PROJECT_PATH/README.md" << EOF
# $NAME

Project scaffolded with the AI Multi-Agent Setup repository.

## Development

This project includes reusable agent instructions, prompts, skills, hooks, MCP templates, and VS
Code settings. Add the application-specific setup and run commands here as the project grows.
EOF

printf "  ✔ README.md created\n"

# ── 5. Initial commit ─────────────────────────────────────────────────────────

git -C "$PROJECT_PATH" add . > /dev/null
git -C "$PROJECT_PATH" commit -q -m "chore: initial project setup from Setup repo"
printf "  ✔ Initial commit created\n"

# ── 6. Optionally create GitHub repo ─────────────────────────────────────────

if [ "$GITHUB_REPO" -eq 1 ]; then
  if command -v gh >/dev/null 2>&1; then
    printf "\n  Creating GitHub repository (%s)...\n" "$VISIBILITY"
    gh repo create "$NAME" "--$VISIBILITY" --source="$PROJECT_PATH" --remote=origin --push
    printf "  ✔ GitHub repo created and pushed\n"
  else
    printf "  ⚠  gh CLI not found — skipping GitHub repo creation.\n"
    printf "     Install from: https://cli.github.com/\n"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

printf "\n  ✅ Project ready: %s\n\n" "$PROJECT_PATH"
printf "  Next steps:\n"
printf "    cd %s\n" "$PROJECT_PATH"
case "$STACK" in
  node)   printf "    npm install\n" ;;
  python) printf "    python -m venv .venv && .venv/bin/pip install -r requirements.txt\n" ;;
  dotnet) printf "    dotnet restore\n" ;;
esac
printf "\n"
