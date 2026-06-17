#!/usr/bin/env bash
set -euo pipefail

export PYTHONIOENCODING="utf-8"

log() {
  printf '[detect] %s\n' "$*"
}

has_file() {
  local path="$1"
  [[ -f "$path" ]]
}

has_dir() {
  local path="$1"
  [[ -d "$path" ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

find_git_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

read_package_name() {
  local package_json="$1"
  if has_file "$package_json"; then
    python - <<'PY' "$package_json"
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding='utf-8'))
    print(data.get('name', ''))
except Exception:
    print('')
PY
  fi
}

detect_default_branch() {
  git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}' || true
}

detect_github_url() {
  git remote get-url origin 2>/dev/null | sed 's/\.git$//' || true
}

detect_package_manager() {
  local root="$1"
  if has_file "$root/pnpm-lock.yaml"; then
    printf 'pnpm\n'
    return
  fi
  if has_file "$root/yarn.lock"; then
    printf 'yarn\n'
    return
  fi
  if has_file "$root/package-lock.json"; then
    printf 'npm\n'
    return
  fi
  if has_file "$root/requirements.txt" || has_file "$root/pyproject.toml"; then
    printf 'pip\n'
    return
  fi
  if has_file "$root/pom.xml"; then
    printf 'maven\n'
    return
  fi
  if has_file "$root/gradlew" || has_file "$root/gradlew.bat" || has_file "$root/build.gradle" || has_file "$root/build.gradle.kts"; then
    printf 'gradle\n'
    return
  fi
  if has_file "$root/go.mod"; then
    printf 'go\n'
    return
  fi
  printf 'npm\n'
}

detect_stack_type() {
  local root="$1"
  if has_file "$root/pnpm-workspace.yaml" || has_file "$root/turbo.json" || has_file "$root/nx.json" || has_file "$root/lerna.json"; then
    printf 'node-monorepo\n'
    return
  fi
  if has_file "$root/package.json"; then
    printf 'node-single\n'
    return
  fi
  if has_file "$root/requirements.txt" || has_file "$root/pyproject.toml"; then
    printf 'python\n'
    return
  fi
  if has_file "$root/pom.xml" || has_file "$root/build.gradle" || has_file "$root/build.gradle.kts"; then
    printf 'java\n'
    return
  fi
  if has_file "$root/go.mod"; then
    printf 'go\n'
    return
  fi
  printf 'node-single\n'
}

detect_monorepo_tool() {
  local root="$1"
  if has_file "$root/turbo.json"; then
    printf 'turborepo\n'
    return
  fi
  if has_file "$root/nx.json"; then
    printf 'nx\n'
    return
  fi
  if has_file "$root/lerna.json"; then
    printf 'lerna\n'
    return
  fi
  printf 'none\n'
}

json_array_from_lines() {
  python - <<'PY'
import json, sys
items = [line.rstrip('\n') for line in sys.stdin if line.rstrip('\n')]
print(json.dumps(items, ensure_ascii=False))
PY
}

detect_apps_json() {
  local root="$1"
  local apps_dir="$root/apps"
  if ! has_dir "$apps_dir"; then
    printf '[]\n'
    return
  fi

  python - <<'PY' "$apps_dir"
import json, sys
from pathlib import Path
apps_dir = Path(sys.argv[1])
results = []
for child in sorted(apps_dir.iterdir()):
    if not child.is_dir():
        continue
    package_json = child / 'package.json'
    name = child.name
    if package_json.exists():
        try:
            data = json.loads(package_json.read_text(encoding='utf-8'))
            name = data.get('name') or name
        except Exception:
            pass
    scope = name.split('/')[-1].replace('bi-', '').replace('app-', '')
    results.append({
        'name': name,
        'path': str(child.relative_to(apps_dir.parent)).replace('\\', '/'),
        'scope': scope,
    })
print(json.dumps(results, ensure_ascii=False))
PY
}

detect_node_script_command() {
  local root="$1"
  local script="$2"
  local pm
  pm="$(detect_package_manager "$root")"

  if ! has_file "$root/package.json"; then
    printf '\n'
    return
  fi

  python - <<'PY' "$root/package.json" "$pm" "$script"
import json, sys
from pathlib import Path
package_json, pm, script = sys.argv[1:]
try:
    data = json.loads(Path(package_json).read_text(encoding='utf-8'))
except Exception:
    print('')
    raise SystemExit
scripts = data.get('scripts') or {}
if script not in scripts:
    print('')
    raise SystemExit
if pm == 'npm':
    print(f'npm run {script}')
elif pm == 'yarn':
    print(f'yarn {script}')
else:
    print(f'{pm} {script}')
PY
}

detect_node_typecheck_command() {
  local root="$1"
  local script_cmd
  script_cmd="$(detect_node_script_command "$root" typecheck)"
  if [[ -n "$script_cmd" ]]; then
    printf '%s\n' "$script_cmd"
    return
  fi

  script_cmd="$(detect_node_script_command "$root" type-check)"
  if [[ -n "$script_cmd" ]]; then
    printf '%s\n' "$script_cmd"
    return
  fi

  if has_file "$root/tsconfig.json" || has_dir "$root/apps"; then
    printf 'npx tsc --noEmit\n'
    return
  fi

  printf '\n'
}

detect_node_lint_command() {
  local root="$1"
  detect_node_script_command "$root" lint
}

detect_node_test_command() {
  local root="$1"
  local script_cmd
  script_cmd="$(detect_node_script_command "$root" test)"
  if [[ -n "$script_cmd" ]]; then
    printf '%s\n' "$script_cmd"
    return
  fi

  if has_file "$root/vitest.config.ts" || has_file "$root/vitest.config.js" || has_file "$root/jest.config.js" || has_file "$root/jest.config.ts"; then
    local pm
    pm="$(detect_package_manager "$root")"
    case "$pm" in
      pnpm) printf 'pnpm test\n' ;;
      npm) printf 'npm test\n' ;;
      yarn) printf 'yarn test\n' ;;
      *) printf '\n' ;;
    esac
    return
  fi

  printf '\n'
}

detect_node_build_command() {
  local root="$1"
  detect_node_script_command "$root" build
}

gradle_command() {
  local root="$1"
  if has_file "$root/gradlew"; then
    printf './gradlew'
    return
  fi
  if has_file "$root/gradlew.bat"; then
    printf './gradlew.bat'
    return
  fi
  printf 'gradle'
}

detect_quality_gate_command() {
  local root="$1"
  local gate="$2"
  local pm
  pm="$(detect_package_manager "$root")"

  case "$gate" in
    compile)
      case "$pm" in
        pnpm|npm|yarn)
          detect_node_typecheck_command "$root"
          ;;
        pip)
          printf 'python -m compileall .\n'
          ;;
        maven)
          printf 'mvn -q -DskipTests compile\n'
          ;;
        gradle)
          printf '%s testClasses\n' "$(gradle_command "$root")"
          ;;
        go)
          printf "go test ./... -run '^$'\n"
          ;;
        *)
          printf '\n'
          ;;
      esac
      ;;
    typecheck)
      case "$pm" in
        pnpm|npm|yarn)
          detect_node_typecheck_command "$root"
          ;;
        *)
          printf '\n'
          ;;
      esac
      ;;
    lint)
      case "$pm" in
        pnpm|npm|yarn)
          detect_node_lint_command "$root"
          ;;
        pip)
          printf 'ruff check .\n'
          ;;
        go)
          printf 'go vet ./...\n'
          ;;
        *)
          printf '\n'
          ;;
      esac
      ;;
    test)
      case "$pm" in
        pnpm|npm|yarn)
          detect_node_test_command "$root"
          ;;
        pip)
          printf 'pytest\n'
          ;;
        maven)
          printf 'mvn test\n'
          ;;
        gradle)
          printf '%s test\n' "$(gradle_command "$root")"
          ;;
        go)
          printf 'go test ./...\n'
          ;;
        *)
          printf '\n'
          ;;
      esac
      ;;
    build)
      case "$pm" in
        pnpm|npm|yarn)
          detect_node_build_command "$root"
          ;;
        maven)
          printf 'mvn -q -DskipTests package\n'
          ;;
        gradle)
          printf '%s build\n' "$(gradle_command "$root")"
          ;;
        go)
          printf 'go build ./...\n'
          ;;
        *)
          printf '\n'
          ;;
      esac
      ;;
    *)
      printf '\n'
      ;;
  esac
}

detect_extras_json() {
  local root="$1"
  local extras=()
  if has_file "$root/prisma/schema.prisma" || has_file "$root/apps/bi-backend/prisma/schema.prisma"; then
    extras+=("prisma")
  fi
  if has_file "$root/apps/bi-backend/package.json"; then
    extras+=("backend-vitest")
  fi
  printf '%s\n' "${extras[@]:-}" | json_array_from_lines
}

generate_config_yaml() {
  local root="$1"
  local project_name
  local default_branch
  local github_url
  local stack_type
  local package_manager
  local monorepo_tool
  local apps_json
  local extras_json
  local compile_cmd
  local typecheck_cmd
  local lint_cmd
  local test_cmd
  local build_cmd

  project_name="$(basename "$root")"
  default_branch="$(detect_default_branch)"
  github_url="$(detect_github_url)"
  stack_type="$(detect_stack_type "$root")"
  package_manager="$(detect_package_manager "$root")"
  monorepo_tool="$(detect_monorepo_tool "$root")"
  apps_json="$(detect_apps_json "$root")"
  extras_json="$(detect_extras_json "$root")"
  compile_cmd="$(detect_quality_gate_command "$root" compile)"
  typecheck_cmd="$(detect_quality_gate_command "$root" typecheck)"
  lint_cmd="$(detect_quality_gate_command "$root" lint)"
  test_cmd="$(detect_quality_gate_command "$root" test)"
  build_cmd="$(detect_quality_gate_command "$root" build)"

  python - <<'PY' "$project_name" "$default_branch" "$github_url" "$stack_type" "$package_manager" "$monorepo_tool" "$apps_json" "$extras_json" "$compile_cmd" "$typecheck_cmd" "$lint_cmd" "$test_cmd" "$build_cmd"
import json, sys
project_name, default_branch, github_url, stack_type, package_manager, monorepo_tool, apps_json, extras_json, compile_cmd, typecheck_cmd, lint_cmd, test_cmd, build_cmd = sys.argv[1:]
apps = json.loads(apps_json)
extras = json.loads(extras_json)
scopes = [{"name": app["name"], "path": app["path"], "label": app["scope"]} for app in apps] or [{"name": "app", "path": ".", "label": "app"}]
lines = [
    'project:',
    f'  name: "{project_name}"',
    '  requirements_dir: "docs/requirements"',
    '  templates_dir: "docs/templates"',
    '',
    'repository:',
    f'  github_url: "{github_url}"',
    f'  default_branch: "{default_branch or "main"}"',
    '  project_path: ""',
    '',
    'stack:',
    f'  type: "{stack_type}"',
    f'  package_manager: "{package_manager}"',
    '  monorepo:',
    f'    tool: "{monorepo_tool}"',
    '    apps:',
]
for app in apps:
    lines.extend([
        f'      - name: "{app["name"]}"',
        f'        path: "{app["path"]}"',
        f'        scope: "{app["scope"]}"',
    ])
if not apps:
    lines.append('      []')
lines.extend([
    '  quality_gates:',
    f'    compile: {{ enabled: {str(bool(compile_cmd)).lower()}, command: "{compile_cmd}" }}',
    f'    typecheck: {{ enabled: {str(bool(typecheck_cmd)).lower()}, command: "{typecheck_cmd}" }}',
    f'    lint: {{ enabled: {str(bool(lint_cmd)).lower()}, command: "{lint_cmd}" }}',
    f'    test: {{ enabled: {str(bool(test_cmd)).lower()}, command: "{test_cmd}" }}',
    f'    build: {{ enabled: {str(bool(build_cmd)).lower()}, command: "{build_cmd}" }}',
    f'  extras: {json.dumps(extras, ensure_ascii=False)}',
    '',
    'scopes:',
])
for scope in scopes:
    lines.extend([
        f'  - name: "{scope["name"]}"',
        f'    path: "{scope["path"]}"',
        f'    label: "{scope["label"]}"',
    ])
lines.extend([
    '',
    'domain:',
    '  name: ""',
    '  principle: ""',
    '  check_questions: []',
    '',
    'labels:',
    '  types: ["feature", "task", "bug", "refactor", "docs", "chore"]',
    '  priorities: ["P0", "P1", "P2", "P3"]',
    '  statuses: ["todo", "in-progress", "in-review", "done"]',
    '',
    'review:',
    '  dimensions:',
    '    - { name: "correctness", description: "逻辑正确性、边界条件、错误处理" }',
    '    - { name: "code-standards", description: "类型安全、命名、模块结构" }',
    '    - { name: "security", description: "硬编码密钥、输入校验、注入风险、鉴权" }',
    '    - { name: "performance", description: "N+1 查询、不必要加载、分页、缓存" }',
    '    - { name: "testing", description: "新代码有测试、断言有意义" }',
    '    - { name: "documentation", description: "文档更新、接口文档" }',
    '    - { name: "deployment", description: "DB migration、环境变量、Dockerfile 变更" }',
    '',
    'release:',
    '  version_file: "package.json"',
    '  changelog_file: "CHANGELOG.md"',
    '  conventional_commits: true',
    '',
    'deploy:',
    '  enabled: false',
    '  environments_dir: ""',
    '  source_paths: []',
    '  service_aliases: {}',
])
print('\n'.join(lines))
PY
}

if [[ "${1:-}" == "--config" ]]; then
  generate_config_yaml "${2:-$(find_git_root)}"
fi
