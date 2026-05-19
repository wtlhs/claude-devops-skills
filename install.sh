#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODE="project"
TARGET_DIR="$(pwd)"
TARGET_EXPLICIT=false
SKIP_TEMPLATES=false
SKIP_LABELS=false
DRY_RUN=false
REPO_URL="https://github.com/wtlhs/claude-devops-skills.git"

log() {
  printf '[install] %s\n' "$*"
}

fail() {
  printf '[install] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --target <dir>         指定目标项目目录
  --global               安装到 ~/.claude/commands/
  --skip-templates       不生成 GitHub 模板和规则文件
  --skip-labels          不创建 GitHub labels
  --dry-run              只打印将要执行的动作
  -h, --help             显示帮助
EOF
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run]'
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return
  fi
  "$@"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)
        [[ $# -ge 2 ]] || fail "--target requires a directory"
        TARGET_DIR="$2"
        TARGET_EXPLICIT=true
        shift 2
        ;;
      --global)
        MODE="global"
        shift
        ;;
      --skip-templates)
        SKIP_TEMPLATES=true
        shift
        ;;
      --skip-labels)
        SKIP_LABELS=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done
}

ensure_target() {
  [[ -d "$TARGET_DIR" ]] || fail "Target directory does not exist: $TARGET_DIR"
  if [[ "$MODE" == "global" && "$TARGET_EXPLICIT" == false ]]; then
    log "Global mode without --target: only install commands to ~/.claude"
  fi
}

install_root() {
  if [[ "$MODE" == "global" ]]; then
    printf '%s\n' "$HOME/.claude"
  else
    printf '%s\n' "$TARGET_DIR/.claude"
  fi
}

project_root() {
  if [[ "$MODE" == "global" ]]; then
    printf '%s\n' "$TARGET_DIR"
  else
    printf '%s\n' "$TARGET_DIR"
  fi
}

should_scaffold_project() {
  [[ "$MODE" != "global" || "$TARGET_EXPLICIT" == true ]]
}

copy_commands() {
  local root="$1"
  run mkdir -p "$root/commands"
  for file in "$SCRIPT_DIR"/commands/*.md; do
    [[ -f "$file" ]] || continue
    local base
    base="$(basename "$file")"
    if [[ -L "$root/commands/$base" ]]; then
      fail "Refuse to overwrite symlink: $root/commands/$base"
    fi
    if [[ -f "$root/commands/$base" ]]; then
      log "Skip existing command: $root/commands/$base"
      continue
    fi
    run cp "$file" "$root/commands/$base"
  done
}

detect_stack_type_for_ci() {
  local project="$1"
  local config_content
  config_content="$(bash "$SCRIPT_DIR/lib/detect.sh" --config "$project")"
  CLAUDE_DEVOPS_CONFIG="$config_content" python - <<'PY'
import os
stack_type = 'node-single'
for raw_line in os.environ.get('CLAUDE_DEVOPS_CONFIG', '').splitlines():
    line = raw_line.rstrip('\n')
    if line.startswith('  type: "'):
        stack_type = line.split('"', 2)[1]
        break
print(stack_type)
PY
}

copy_rules_and_templates() {
  local project="$1"
  run mkdir -p "$project/.claude/rules" "$project/.github/ISSUE_TEMPLATE" "$project/.github/workflows"

  if [[ -L "$project/.claude/rules/devops-auto-triggers.md" ]]; then
    fail "Refuse to overwrite symlink: $project/.claude/rules/devops-auto-triggers.md"
  fi
  if [[ -f "$project/.claude/rules/devops-auto-triggers.md" ]]; then
    log "Skip existing rule file: $project/.claude/rules/devops-auto-triggers.md"
  else
    run cp "$SCRIPT_DIR/rules/devops-auto-triggers.md" "$project/.claude/rules/devops-auto-triggers.md"
  fi

  for src in "$SCRIPT_DIR"/templates/github/ISSUE_TEMPLATE/*; do
    [[ -f "$src" ]] || continue
    local dest="$project/.github/ISSUE_TEMPLATE/$(basename "$src")"
    if [[ -L "$dest" ]]; then
      fail "Refuse to overwrite symlink: $dest"
    fi
    if [[ -f "$dest" ]]; then
      log "Skip existing template: $dest"
      continue
    fi
    run cp "$src" "$dest"
  done

  if [[ -L "$project/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
    fail "Refuse to overwrite symlink: $project/.github/PULL_REQUEST_TEMPLATE.md"
  fi
  if [[ ! -f "$project/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
    run cp "$SCRIPT_DIR/templates/github/PULL_REQUEST_TEMPLATE.md" "$project/.github/PULL_REQUEST_TEMPLATE.md"
  else
    log "Skip existing PR template"
  fi

  if [[ -L "$project/.github/workflows/ci.yml" ]]; then
    fail "Refuse to overwrite symlink: $project/.github/workflows/ci.yml"
  fi
  if [[ ! -f "$project/.github/workflows/ci.yml" ]]; then
    local stack_type
    stack_type="$(detect_stack_type_for_ci "$project")"
    case "$stack_type" in
      python)
        run cp "$SCRIPT_DIR/templates/github/workflows/ci-python.yml" "$project/.github/workflows/ci.yml"
        ;;
      java)
        run cp "$SCRIPT_DIR/templates/github/workflows/ci-java.yml" "$project/.github/workflows/ci.yml"
        ;;
      *)
        run cp "$SCRIPT_DIR/templates/github/workflows/ci-node.yml" "$project/.github/workflows/ci.yml"
        ;;
    esac
  else
    log "Skip existing CI workflow"
  fi
}

merge_top_level_yaml_sections() {
  local base_file="$1"
  local override_file="$2"
  local output_file="$3"

  python - <<'PY' "$base_file" "$override_file" "$output_file"
import sys
from pathlib import Path

base_path = Path(sys.argv[1])
override_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])


def split_sections(text: str):
    sections = []
    current_key = None
    current_lines = []

    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        is_top_level = line and not line.startswith((' ', '\t')) and stripped.endswith(':') and ':' in stripped[:-1] + ':'
        if is_top_level:
            if current_key is not None:
                sections.append((current_key, ''.join(current_lines)))
            current_key = stripped[:-1]
            current_lines = [line]
        else:
            if current_key is None:
                current_key = '__preamble__'
                current_lines = []
            current_lines.append(line)

    if current_key is not None:
        sections.append((current_key, ''.join(current_lines)))

    return sections

base_text = base_path.read_text(encoding='utf-8')
override_text = override_path.read_text(encoding='utf-8')
base_sections = split_sections(base_text)
override_sections = split_sections(override_text)
override_map = {key: body for key, body in override_sections if key != '__preamble__'}
existing_keys = [key for key, _ in base_sections]
merged_sections = []

for key, body in base_sections:
    if key in override_map:
        merged_sections.append(override_map[key])
    else:
        merged_sections.append(body)

for key, body in override_sections:
    if key != '__preamble__' and key not in existing_keys:
        if merged_sections and not merged_sections[-1].endswith('\n\n'):
            if merged_sections[-1].endswith('\n'):
                merged_sections[-1] += '\n'
            else:
                merged_sections[-1] += '\n\n'
        merged_sections.append(body)

output_path.write_text(''.join(merged_sections), encoding='utf-8')
PY
}

apply_project_override() {
  local project="$1"
  local config_path="$2"
  local override_path="$project/.claude/claude-devops.project.yml"

  if [[ ! -f "$override_path" ]]; then
    return
  fi

  log "Apply project override: $override_path"

  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] merge override %q into %q\n' "$override_path" "$config_path"
    return
  fi

  local temp_output
  temp_output="$(mktemp)"
  merge_top_level_yaml_sections "$config_path" "$override_path" "$temp_output"
  mv "$temp_output" "$config_path"
}

write_config() {
  local project="$1"
  local config_path="$project/.claude-devops.yml"
  if [[ -L "$config_path" ]]; then
    fail "Refuse to overwrite symlink: $config_path"
  fi
  if [[ -f "$config_path" ]]; then
    log "Skip existing config: $config_path"
    apply_project_override "$project" "$config_path"
    return
  fi
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] bash %q --config %q > %q\n' "$SCRIPT_DIR/lib/detect.sh" "$project" "$config_path"
    printf '[dry-run] apply project override if %q exists\n' "$project/.claude/claude-devops.project.yml"
    return
  fi
  bash "$SCRIPT_DIR/lib/detect.sh" --config "$project" > "$config_path"
  apply_project_override "$project" "$config_path"
}

extract_github_repo() {
  local project="$1"
  local remote_url
  remote_url="$(git -C "$project" remote get-url origin 2>/dev/null || true)"
  REMOTE_URL="$remote_url" python - <<'PY'
import os, re
raw = os.environ.get('REMOTE_URL', '').strip()
match = re.search(r'github\.com[:/](.+?)(?:\.git)?$', raw)
print(match.group(1) if match else '')
PY
}

is_git_repo() {
  local project="$1"
  git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

setup_labels() {
  local project="$1"
  if ! command -v gh >/dev/null 2>&1; then
    log "gh CLI not found, skip labels"
    return
  fi
  if ! is_git_repo "$project"; then
    log "Target is not a git repository, skip labels"
    return
  fi
  local scopes_csv
  local repo_slug
  scopes_csv="$(python - <<'PY' "$project/.claude-devops.yml"
import sys
from pathlib import Path
path = Path(sys.argv[1])
if not path.exists():
    print('app')
    raise SystemExit
lines = path.read_text(encoding='utf-8').splitlines()
labels = []
for idx, line in enumerate(lines):
    if line.strip() == 'scopes:':
        j = idx + 1
        while j < len(lines):
            current = lines[j].strip()
            if current.startswith('label:'):
                labels.append(current.split(':', 1)[1].strip().strip('"'))
            if current and not lines[j].startswith('  -') and not lines[j].startswith('    ') and not current.startswith('scopes:'):
                break
            j += 1
        break
print(','.join(labels or ['app']))
PY
)"
  repo_slug="$(extract_github_repo "$project")"
  if [[ -z "$repo_slug" ]]; then
    log "Cannot determine GitHub repository for $project, skip labels"
    return
  fi
  run bash "$SCRIPT_DIR/lib/labels.sh" --setup "$scopes_csv" "$repo_slug"
}

main() {
  parse_args "$@"
  ensure_target

  local claude_root
  local project
  claude_root="$(install_root)"
  project="$(project_root)"

  log "Mode: $MODE"
  log "Target project: $project"
  log "Claude root: $claude_root"

  copy_commands "$claude_root"

  if should_scaffold_project; then
    write_config "$project"

    if [[ "$SKIP_TEMPLATES" == false ]]; then
      copy_rules_and_templates "$project"
    else
      log "Skip templates and rules"
    fi

    if [[ "$SKIP_LABELS" == false ]]; then
      setup_labels "$project"
    else
      log "Skip labels"
    fi
  else
    log "Global mode: skip project scaffold, rules, templates, and labels"
  fi

  log "Install completed"
}

main "$@"
