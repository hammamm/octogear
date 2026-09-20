#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <feature-name> [features-directory]" >&2
  exit 1
fi

feature_name="$1"
features_directory="${2:-lib/features}"

if [[ ! "$feature_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Error: feature name may only contain letters, numbers, underscores, and hyphens." >&2
  exit 1
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$features_directory" = /* ]]; then
  features_root="$features_directory"
else
  features_root="$script_directory/$features_directory"
fi

feature_directory="$features_root/$feature_name"
file_feature_name="$(printf '%s' "$feature_name" | tr '[:upper:]-' '[:lower:]_')"
class_feature_name="$(printf '%s' "$feature_name" | awk -F '[-_]' '{ for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), tolower(substr($i, 2)) }')"
repository_file="$feature_directory/data/repositories/${file_feature_name}_repository_impl.dart"
domain_repository_file="$feature_directory/domain/repository/${file_feature_name}_repository.dart"

mkdir -p \
  "$feature_directory/data/models" \
  "$feature_directory/data/repositories" \
  "$feature_directory/domain/entity" \
  "$feature_directory/domain/repository" \
  "$feature_directory/domain/use_cases" \
  "$feature_directory/presentation/widgets" \
  "$feature_directory/presentation/screens" \
  "$feature_directory/presentation/providers"

if [[ ! -e "$repository_file" ]]; then
  printf 'class %sRepositoryImpl {}\n' "$class_feature_name" > "$repository_file"
fi

if [[ ! -e "$domain_repository_file" ]]; then
  printf 'abstract class %sRepository {}\n' "$class_feature_name" > "$domain_repository_file"
fi

echo "Created feature: $feature_directory"
