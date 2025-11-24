---
slug: github-push-commits
title: Bash Script to Push Committed and Uncommitted Changes Across Multiple Git Repositories
repo: justin-napolitano/push-commits
githubUrl: https://github.com/justin-napolitano/push-commits
generatedAt: '2025-11-23T09:29:09.060999Z'
source: github-auto
summary: >-
  Overview of a Bash script that automates pushing committed and uncommitted changes across multiple
  git repositories with branch handling and blacklist support.
tags:
  - bash
  - git
  - git-branches
seoPrimaryKeyword: push committed and uncommitted changes script
seoSecondaryKeywords:
  - git automation
  - multi-repository git
  - bash git script
seoOptimized: true
---

# Push Committed and Uncommitted Changes Script: Technical Overview

## Motivation

Managing multiple git repositories manually can be time-consuming and error-prone, especially when needing to keep all branches up to date, track both committed and uncommitted changes, and push changes consistently. This script addresses the problem by automating these tasks across all repositories within a specified directory.

## Problem Statement

Developers often have numerous repositories stored locally. Ensuring each repository is synchronized with its remote, and that local changes—both committed and uncommitted—are properly pushed, requires repetitive manual commands. Moreover, uncommitted changes risk being overlooked, and pushing commits directly on the `main` branch without review is generally discouraged.

## Solution Overview

The script traverses a root directory containing multiple git repositories. For each repository, it:

- Pulls updates for all branches.
- Detects committed changes and pushes them.
- Detects uncommitted changes, creates a dedicated `uncommitted` branch, commits those changes with a message referencing the original branch, and pushes the branch.
- For the `main` branch, if committed changes are found, moves those changes to a new branch named `bad-practice` and pushes that branch instead of pushing directly to `main`.
- Skips repositories listed in a blacklist file.
- Confirms repository ownership by checking the remote URL for the configured GitHub username to avoid pushing to unrelated repositories.

## Implementation Details

### Script Environment

- Written in Bash to leverage native shell and git command line tools.
- Uses environment variables and script arguments for configuration:
  - `DEFAULT_ROOT_DIR` sets the default directory containing repositories.
  - `BLACKLIST_FILE` points to a file listing repositories to exclude.
  - `GITHUB_USERNAME` identifies the user to verify repository ownership.

### Argument Parsing

- Supports a `--local` flag (exact behavior inferred as a mode toggle).
- Accepts an optional root directory argument, falling back to the default if not provided.

### Repository Filtering

- The script checks each repository against the blacklist file. If the repository path matches an entry, it is skipped.
- Ownership is confirmed by inspecting the remote origin URL for the GitHub username. This prevents accidental operations on repositories not owned by the user.

### Branch Handling

- Fetches all branches using `git fetch --all`.
- Iterates over remote branches to pull updates.

### Change Detection and Push Logic

- For committed changes on any branch, the script pushes those commits to the remote.
- For uncommitted changes:
  - Creates a new branch named `uncommitted`.
  - Commits the uncommitted changes with a message that references the original branch.
  - Pushes the `uncommitted` branch to the remote.
- For the `main` branch, if committed changes exist, the script moves those changes to a new branch called `bad-practice` and pushes that branch instead of pushing directly to `main`. This enforces a workflow discouraging direct commits to `main`.

### Blacklist Handling

- The blacklist file is expected to contain repository paths, one per line.
- The script verifies the existence of the blacklist file before attempting to read it.

### Assumptions and Limitations

- The script assumes the user has proper permissions to access and modify all repositories.
- The blacklist file format is simple and expects exact path matches.
- The `--local` mode's specific behavior is not fully documented in the available context.
- Error handling and logging are minimal based on the sampled code.

## Practical Considerations

- This script is suitable for developers managing multiple local repositories who want to automate synchronization and pushing of changes.
- It enforces a safer workflow by isolating uncommitted changes and discouraging direct pushes to `main`.
- The script requires customization of paths and username before use.

## Summary

The `push-commits` script automates routine git operations across multiple repositories, improving efficiency and enforcing safer git workflows. It leverages Bash and git CLI commands to pull all branches, detect and push committed and uncommitted changes, and respects repository ownership and blacklisting. While functional, it could benefit from enhanced configurability, error handling, and documentation for broader adoption.
