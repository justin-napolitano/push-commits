#!/bin/bash

# Define the default root directory where your repos are located
DEFAULT_ROOT_DIR="/home/cobra/Repos"

# Define the default blacklist file location
BLACKLIST_FILE="/etc/commit_push_blacklist.conf"

# Define the GitHub username to check against
GITHUB_USERNAME="justin-napolitano"

# Parse arguments
LOCAL_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            LOCAL_MODE=true
            shift
            ;;
        *)
            ROOT_DIR=$1
            shift
            ;;
    esac
done

# Set ROOT_DIR to default if not set
ROOT_DIR=${ROOT_DIR:-$DEFAULT_ROOT_DIR}

# Export the BLACKLIST_FILE and GITHUB_USERNAME variables so they are available in subshells
export BLACKLIST_FILE
export GITHUB_USERNAME

# Function to check if a repository is blacklisted
is_blacklisted() {
    local repo_dir=$1
    echo "    Checking for Blacklisted $repo_dir in $BLACKLIST_FILE"
    if [ -z "$BLACKLIST_FILE" ]; then
        echo "    BLACKLIST_FILE is not set"
        return 1
    fi
    if [ ! -f "$BLACKLIST_FILE" ]; then
        echo "    Blacklist file does not exist: $BLACKLIST_FILE"
        return 1
    fi
    grep -qxF "$repo_dir" "$BLACKLIST_FILE"
    local result=$?
    if [ $result -eq 0 ]; then
        echo "    $repo_dir is blacklisted"
    else
        echo "    $repo_dir is not blacklisted"
    fi
    return $result
}

# Function to check if a repository belongs to the specified user
belongs_to_user() {
    local repo_dir=$1
    local remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null)
    if [[ "$remote_url" == *"$GITHUB_USERNAME"* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to push only committed changes across all branches
push_committed_changes() {
    local repo_dir=$1
    echo "Processing repository in $repo_dir"
    cd "$repo_dir" || return

    if is_blacklisted "$repo_dir"; then
        echo "    Repository is blacklisted, skipping $repo_dir"
        cd - || return
        return
    fi

    if ! belongs_to_user "$repo_dir"; then
        echo "    Repository does not belong to user $GITHUB_USERNAME, skipping $repo_dir"
        cd - || return
        return
    fi

    # Fetch remote branches
    git fetch origin

    # Get all branches
    branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)

    for branch in $branches; do
        git checkout "$branch"
        if [ "$branch" == "main" ]; then
            # Check if there are committed changes on the main branch
            if git log origin/main..HEAD | grep -q "."; then
                echo "    Committed changes found on main branch in $repo_dir"

                # Create and switch to the bad-practice branch
                git checkout -b bad-practice

                # Push the bad-practice branch to the remote
                git push origin bad-practice

                echo "    Changes have been moved to and pushed on the bad-practice branch in $repo_dir"
            else
                echo "    No committed changes to push on the main branch in $repo_dir"
            fi
        else
            # Check if there are committed changes to push on the current branch
            if git log origin/"$branch"..HEAD | grep -q "."; then
                echo "    Committed changes found on branch $branch in $repo_dir"
                git push origin "$branch"
                echo "    Changes have been pushed to remote branch $branch in $repo_dir"
            else
                echo "    No committed changes to push on branch $branch in $repo_dir"
            fi
        fi
    done

    cd - || return
}

# Export the functions so they can be used by find -exec
export -f push_committed_changes
export -f is_blacklisted
export -f belongs_to_user

if $LOCAL_MODE; then
    echo "Running in local mode. Processing the current working directory."
    push_committed_changes "$(pwd)"
else
    echo "Starting push process for repositories in $ROOT_DIR"

    # Ensure the blacklist file exists
    if [ ! -f "$BLACKLIST_FILE" ]; then
        echo "Blacklist file not found: $BLACKLIST_FILE"
        exit 1
    fi

    # Find all .git directories and push committed changes across all branches
    find "$ROOT_DIR" -name ".git" -type d -exec bash -c 'push_committed_changes "$(dirname "{}")"' \;
fi

echo "All repositories processed."
