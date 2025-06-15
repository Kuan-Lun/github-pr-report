# GitHub PR Contribution Reporter

This is a Bash script that generates a Markdown table summarizing pull requests submitted by a specific GitHub user to repositories they do **not own**.

It fetches repository metadata and PR links, and by default only includes **merged pull requests**. Output is written to a Markdown file.

## Features

- Lists public pull requests made by a given user to other repositories
- Excludes PRs to repositories owned by the same user
- Fetches repository metadata: stars, forks, watchers, open issues, contributors
- By default, includes only merged PRs
- Supports listing all PRs (`all` mode)
- Outputs a Markdown table with repository and PR information
- Customizable output file name

## Requirements

- Bash
- [`jq`](https://stedolan.github.io/jq/) (for JSON parsing)
- GitHub Personal Access Token (with `public_repo` scope)

## Usage

```bash
./generate_pr_report.sh <github_token> <github_username> [filter] [output_file]
```

- `github_token`: Your GitHub personal access token (recommended: use environment variable or `.gitignore`-safe file)
- `github_username`: GitHub username to analyze
- `filter` *(optional)*:

  - `merged` (default): Only include merged PRs
  - `all`: Include all PRs (merged and unmerged)
- `output_file` *(optional)*: Output file name (default: `<username>-report-<date>.md`, e.g., `alice-report-20250615.md`)

## Examples

Generate a report of **merged** PRs submitted by `alice`:

```bash
./generate_pr_report.sh ghp_abc123456789 alice
```

Generate a report of **all** PRs (including open/unmerged) and save to a custom file:

```bash
./generate_pr_report.sh ghp_abc123456789 alice all full-report.md
```

## Sample Output

The script outputs a Markdown table like this:

| REPO                                                      | Stars | Forks | Watchers | Issues | Contributors | PRs                                                                                                 |
| --------------------------------------------------------- | ----- | ----- | -------- | ------ | ------------ | --------------------------------------------------------------------------------------------------- |
| [someuser/somerepo](https://github.com/someuser/somerepo) | 134   | 27    | 5        | 12     | 8            | [#1](https://github.com/someuser/somerepo/pull/1) [#3](https://github.com/someuser/somerepo/pull/3) |

## Notes

- Only **public repositories and public pull requests** are included.
- PRs to the user's own repositories are automatically excluded.
- Uses the GitHub REST API v3. Authenticated requests support up to 5000 calls/hour.
- For users with many PRs, the script handles pagination and metadata requests automatically.
- Performance may be slower in `all` mode due to additional API calls.

## License

This project is distributed under the terms of the GNU General Public Licence (GPL). For detailed licence terms, see the `LICENSE` file included in this distribution.
