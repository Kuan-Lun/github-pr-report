# GitHub Contribution Report Generator

This script generates a Markdown table summarizing a GitHub user's pull requests (PRs) — and optionally issues — contributed to repositories **not owned** by the user. It is useful for auditing open-source contributions beyond green squares or self-starred repos.

## Features

* Fetches **pull requests** (merged or all) made to others' repositories
* (Optional) Fetches **issues** opened in others' repositories
* Reports repository stats: stars, forks, watchers, open issues, contributors
* Outputs to a Markdown table file for easy sharing

## Example Output

| REPO                                      | Stars | Forks | Watchers | Issues | Contributors | PRs (merged)                                  | Issues (opened)                                 |
| ----------------------------------------- | ----- | ----- | -------- | ------ | ------------ | --------------------------------------------- | ----------------------------------------------- |
| [some1/repo](https://github.com/some1/repo) | 42    | 7     | 12       | 5      | 9            | [#123](https://github.com/some1/repo/pull/123) | [#456](https://github.com/some1/repo/issues/456) |
| [some2/repo](https://github.com/some2/repo) | 5    | 0     | 1       | 3      | 2            |  | [#789](https://github.com/some2/repo/issues/789) [#1001](https://github.com/some2/repo/issues/1001) |

## Requirements

* Bash (Unix-based OS)
* [`curl`](https://curl.se/)
* [`jq`](https://stedolan.github.io/jq/)
* A [GitHub personal access token](https://github.com/settings/tokens) with `public_repo` scope

## Usage

```bash
bash generate_contrib_report.sh \
  --token <your-github-token> \
  --user <github-username> \
  --filter merged \
  --include-issues true \
  --output <output-file>.md
```

### Parameters

* `--token` (required): Your GitHub personal access token
* `--user` (required): GitHub username to analyze
* `--filter` *(optional)*: `merged` (default) or `all`
* `--include-issues` *(optional)*: `true` (default) or `false`
* `--output` *(optional)*: Output file name (default: `<username>-report-YYYYMMDD.md`)

## Example

```bash
bash generate_contrib_report.sh \
  --token ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --user octocat \
  --filter merged \
  --include-issues true \
  --output octocat-report.md
```

## Notes

* Only PRs and issues **to repositories not owned by the user** are included
* If `--include-issues` is set to `false`, the final column is omitted

## License

This project is distributed under the terms of the GNU General Public Licence (GPL). For detailed licence terms, see the `LICENSE` file included in this distribution.
