# Push Committed and Uncommitted Changes Script

A Bash script designed to automate the process of updating multiple Git repositories within a directory. It pulls all branches, detects committed and uncommitted changes, and pushes those changes to the remote repositories with specific handling for uncommitted changes and the main branch.

---

## Features

- Traverses a specified directory containing multiple Git repositories.
- Pulls updates for all branches in each repository.
- Detects committed changes on any branch and pushes them.
- Detects uncommitted changes, creates a new branch `uncommitted`, commits those changes with a descriptive message, and pushes the branch.
- For the `main` branch, if committed changes exist, moves those changes to a new branch `bad-practice` and pushes it.
- Supports a blacklist to exclude specific repositories from processing.
- Checks repository ownership based on GitHub username to avoid pushing to unrelated repos.

## Tech Stack

- Shell scripting (Bash)
- Git command line tools

## Getting Started

### Prerequisites

- Bash shell
- Git installed and configured
- Proper file system permissions to access and modify the target repositories

### Installation

1. Clone or download the repository.
2. Place the script `pull-commit-push.sh` in a desired location.
3. Modify the script variables if necessary:
   - `DEFAULT_ROOT_DIR`: The root directory containing your git repositories (default: `/home/cobra/Repos`).
   - `BLACKLIST_FILE`: Path to a file listing repositories to exclude (default: `/etc/commit_push_blacklist.conf`).
   - `GITHUB_USERNAME`: Your GitHub username to verify repository ownership.

### Usage

Run the script with optional parameters:

```bash
./pull-commit-push.sh [--local] [root_directory]
```

- `--local`: Enables local mode (behavior assumed, see script).
- `root_directory`: Overrides the default root directory.

Example:

```bash
./pull-commit-push.sh /path/to/repos
```

## Project Structure

- `pull-commit-push.sh`: Main Bash script implementing the functionality.
- `index.md`: Documentation file with project overview and usage instructions.
- `readme.md`: This README file.

## Future Work / Roadmap

- Add detailed logging and error handling.
- Support configuration via external config files or environment variables.
- Add options to customize branch naming conventions.
- Enhance blacklist functionality with pattern matching.
- Add unit and integration tests for critical script functions.
- Provide Docker containerization for consistent environment.

---

*Note: Some assumptions were made about the behavior of `--local` mode and blacklist file format based on partial script content.*