#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[labels] %s\n' "$*"
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    printf 'gh CLI is required to manage labels\n' >&2
    exit 1
  fi
}

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  gh label create "$name" --color "$color" --description "$description" --force >/dev/null 2>&1 || true
}

setup_default_labels() {
  local scopes_csv="${1:-app}"
  local repo_slug="${2:-}"
  local gh_args=()
  IFS=',' read -r -a scopes <<< "$scopes_csv"

  if [[ -n "$repo_slug" ]]; then
    gh_args=(--repo "$repo_slug")
  fi

  for type in feature task bug refactor docs chore; do
    gh label create "type: $type" --color "0075ca" --description "Type label for $type work" "${gh_args[@]}" --force >/dev/null 2>&1 || true
  done

  for priority in P0 P1 P2 P3; do
    gh label create "priority: $priority" --color "d93f0b" --description "Priority level $priority" "${gh_args[@]}" --force >/dev/null 2>&1 || true
  done

  for status in todo in-progress in-review done; do
    gh label create "status: $status" --color "fbca04" --description "Workflow status $status" "${gh_args[@]}" --force >/dev/null 2>&1 || true
  done

  for scope in "${scopes[@]}"; do
    scope="$(printf '%s' "$scope" | xargs)"
    [[ -n "$scope" ]] || continue
    gh label create "scope: $scope" --color "c5def5" --description "Scope label for $scope" "${gh_args[@]}" --force >/dev/null 2>&1 || true
  done
}

if [[ "${1:-}" == "--setup" ]]; then
  require_gh
  setup_default_labels "${2:-app}" "${3:-}"
fi
