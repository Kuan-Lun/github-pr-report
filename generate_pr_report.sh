#!/bin/bash

# ====== Parameter configuration ======
GITHUB_TOKEN="$1"
USERNAME="$2"
FILTER_MODE="$3"  # optional: "all" or "merged"
OUTPUT_FILE="$4"

if [ -z "$GITHUB_TOKEN" ] || [ -z "$USERNAME" ]; then
  echo "Usage: $0 <github-token> <github-username> [filter] [output-file]"
  echo "  filter: 'all' to include all PRs, default is 'merged' only"
  echo "  output-file: optional markdown file name (default: <username>-report-YYYYMMDD.md)"
  exit 1
fi

FILTER_MODE=${FILTER_MODE:-merged}
OUTPUT_FILE=${OUTPUT_FILE:-"${USERNAME}-report-$(date +%Y%m%d).md"}

HEADER_AUTH="Authorization: token $GITHUB_TOKEN"
HEADER_ACCEPT="Accept: application/vnd.github.v3+json"

declare -A REPO_PR_MAP
declare -A REPO_ISSUE_MAP

# ====== Pull Requests ======
echo "Searching PRs by $USERNAME (filter: $FILTER_MODE)..."
page=1
while :; do
  result=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" \
    "https://api.github.com/search/issues?q=type:pr+author:$USERNAME+-user:$USERNAME&per_page=100&page=$page")

  count=$(echo "$result" | jq '.items | length')
  [[ "$count" -eq 0 ]] && break

  while IFS=$'\t' read -r repo_api_url repo_full_name pr_url pr_number; do
    if [ "$FILTER_MODE" == "all" ]; then
      REPO_PR_MAP["$repo_full_name"]+="$pr_number $pr_url"$'\n'
    else
      pr_api_url="https://api.github.com/repos/$repo_full_name/pulls/$pr_number"
      merged=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" "$pr_api_url" | jq '.merged')
      if [ "$merged" == "true" ]; then
        REPO_PR_MAP["$repo_full_name"]+="$pr_number $pr_url"$'\n'
      fi
    fi
  done < <(echo "$result" | jq -r '
    .items[] |
    select(.pull_request != null) |
    [
      .repository_url,
      (.repository_url | sub("https://api.github.com/repos/"; "")),
      .html_url,
      .number
    ] | @tsv')

  ((page++))
done

# ====== Issues ======
echo "Searching issues by $USERNAME..."
page=1
while :; do
  result=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" \
    "https://api.github.com/search/issues?q=type:issue+author:$USERNAME+-user:$USERNAME&per_page=100&page=$page")

  count=$(echo "$result" | jq '.items | length')
  [[ "$count" -eq 0 ]] && break

  while IFS=$'\t' read -r repo_api_url repo_full_name issue_url issue_number; do
    REPO_ISSUE_MAP["$repo_full_name"]+="$issue_number $issue_url"$'\n'
  done < <(echo "$result" | jq -r '
    .items[] |
    [
      .repository_url,
      (.repository_url | sub("https://api.github.com/repos/"; "")),
      .html_url,
      .number
    ] | @tsv')

  ((page++))
done

# ====== Output Markdown table ======
# Determine PR column title
if [ "$FILTER_MODE" = "all" ]; then
  pr_column_title="PRs (all)"
else
  pr_column_title="PRs (merged)"
fi

echo "| REPO | Stars | Forks | Watchers | Issues | Contributors | $pr_column_title | Issues (opened) |" > "$OUTPUT_FILE"
echo "| --- | --- | --- | --- | --- | --- | --- | --- |" >> "$OUTPUT_FILE"

# Union of all repos that have PRs or Issues
repos=$(printf "%s\n%s\n" "${!REPO_PR_MAP[@]}" "${!REPO_ISSUE_MAP[@]}" | sort -u)

for repo in $repos; do
  owner=$(echo "$repo" | cut -d/ -f1)
  name=$(echo "$repo" | cut -d/ -f2)

  meta=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" "https://api.github.com/repos/$repo")
  stars=$(echo "$meta" | jq '.stargazers_count // 0')
  forks=$(echo "$meta" | jq '.forks_count // 0')
  watchers=$(echo "$meta" | jq '.subscribers_count // 0')
  issues=$(echo "$meta" | jq '.open_issues_count // 0')

  contributors=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" \
    "https://api.github.com/repos/$repo/contributors?per_page=1" -I | \
    grep -i '^Link:' | grep -o 'page=[0-9]*>' | sed 's/[^0-9]*//g' | head -n1)

  if [ -z "$contributors" ]; then
    contributors=$(curl -s -H "$HEADER_AUTH" -H "$HEADER_ACCEPT" \
      "https://api.github.com/repos/$repo/contributors?per_page=100" | jq 'length')
  fi
  contributors=$(echo "$contributors" | tr -d '\n')

  prs=""
  while IFS= read -r line; do
    pr_number=$(echo "$line" | awk '{print $1}')
    pr_url=$(echo "$line" | awk '{print $2}')
    [[ "$pr_number" && "$pr_url" == http* ]] && prs+=" [#${pr_number}](${pr_url})"
  done <<< "${REPO_PR_MAP[$repo]}"

  issues_out=""
  while IFS= read -r line; do
    issue_number=$(echo "$line" | awk '{print $1}')
    issue_url=$(echo "$line" | awk '{print $2}')
    [[ "$issue_number" && "$issue_url" == http* ]] && issues_out+=" [#${issue_number}](${issue_url})"
  done <<< "${REPO_ISSUE_MAP[$repo]}"

  echo "| [$repo](https://github.com/$repo) | $stars | $forks | $watchers | $issues | $contributors |$prs |$issues_out |" >> "$OUTPUT_FILE"
done

echo "Done. Output written to: $OUTPUT_FILE"
