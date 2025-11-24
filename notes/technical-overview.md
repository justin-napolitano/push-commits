---
slug: github-push-commits-note-technical-overview
id: github-push-commits-note-technical-overview
title: Push Commits Overview
repo: justin-napolitano/push-commits
githubUrl: https://github.com/justin-napolitano/push-commits
generatedAt: '2025-11-24T18:44:02.471Z'
source: github-auto
summary: >-
  The `push-commits` repository features a Bash script that automates updating
  multiple Git repositories in a directory. It handles committed and uncommitted
  changes, pushing them accordingly.
tags: []
seoPrimaryKeyword: ''
seoSecondaryKeywords: []
seoOptimized: false
topicFamily: null
topicFamilyConfidence: null
kind: note
entryLayout: note
showInProjects: false
showInNotes: true
showInWriting: false
showInLogs: false
---

The `push-commits` repository features a Bash script that automates updating multiple Git repositories in a directory. It handles committed and uncommitted changes, pushing them accordingly.

## Key Features

- Traverses the specified directory of Git repos.
- Pulls all branches for updates.
- Pushes committed changes across branches. 
- Creates new `uncommitted` branches for uncommitted changes.
- Moves committed changes from the `main` branch to a `bad-practice` branch before pushing.
- Supports a blacklist to skip specific repositories.
- Ensures you're pushing to the right repos based on your GitHub username.

## Quick Start

1. Clone the repo.
2. Place `pull-commit-push.sh` in your preferred location.
3. Configure:
   - `DEFAULT_ROOT_DIR`
   - `BLACKLIST_FILE`
   - `GITHUB_USERNAME`

Run the script like this:

```bash
./pull-commit-push.sh [--local] [root_directory]
```

Remember to have Bash and Git installed. Check your permissions for repo modifications.
