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
    echo "    Checking if $repo_dir is blacklisted in $BLACKLIST_FILE"
    if [ -z "$BLACKLIST_FILE" ]; then
        echo "    BLACKLIST_FILE is not set"
        return 1
    fi
    if [ ! -f "$BLACKLIST_FILE" ]; then
        echo "    Blacklist file does not exist: $BLACKLIST_FILE"
        return 1
    fi
    grep -qxF "$repo_dir" "$BLACKLIST_FILE"
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

# Function to check if a remote branch exists
remote_branch_exists() {
    local branch=$1
    local repo_dir=$2
    git -C "$repo_dir" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
    return $?
}

# Function to pull all branches
pull_all_branches() {
    local repo_dir=$1
    echo "Pulling updates in $repo_dir"
    cd "$repo_dir" || return
    
    # Fetch all branches
    git fetch --all
    
    # Get a list of all branches
    branches=$(git branch -r | grep -v '\->')
    
    # Checkout and pull each branch
    for branch in $branches; do
        local_branch=${branch#origin/}
        git checkout "$local_branch" || git checkout -b "$local_branch" "origin/$local_branch"
        git pull origin "$local_branch"
    done
    
    cd - || return
}


# Function to delete local branches not on GitHub
sync_branches() {
    local repo_dir=$1
    echo "Deleting local branches not on GitHub in $repo_dir"
    cd "$repo_dir" || return
    
    # Function to check if a branch exists on the remote
    remote_branch_exists() {
        local branch=$1
        git ls-remote --exit-code --heads origin "$branch" > /dev/null 2>&1
        return $?
    }

    # Get all local branches except the current one
    local_branches=$(git branch | grep -v "^\*")

    for branch in $local_branches; do
        branch=$(echo "$branch" | sed 's/^[ \t]*//;s/[ \t]*$//')  # Trim leading and trailing whitespaces
        if ! remote_branch_exists "$branch"; then
            echo "    Deleting local branch: $branch"
            git branch -d "$branch"
        fi
    done

    echo "Cleanup complete."

    cd - || return
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

    # Get the current branch
    # original_branch=$(git symbolic-ref --short HEAD)

    # Pull all branches first
    pull_all_branches "$repo_dir"

    # Delete local branches not on GitHub
    sync_branches "$repo_dir"

    # Get all branches
    branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)

    for branch in $branches; do
        git checkout "$branch"

        # Handle uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            echo "    Uncommitted changes found on branch $branch in $repo_dir"

            # Stash the uncommitted changes
            git stash -u
            echo "    Uncommitted changes stashed."

            # Create a unique branch name for the uncommitted changes
            new_branch="uncommitted-${branch}-$(date +%Y%m%d%H%M%S)"

            # Create and checkout the new branch
            git checkout -b "$new_branch"
            echo "    Switched to new branch $new_branch."

            # Apply the stashed changes
            git stash pop
            echo "    Stashed changes applied to $new_branch."

            # Commit the changes
            git add .
            git commit -m "Uncommitted changes from branch $branch"
            echo "    Uncommitted changes committed to $new_branch."

            # Push the new branch to the remote repository
            git push --set-upstream origin "$new_branch"
            echo "    Uncommitted changes have been pushed to $new_branch in $repo_dir."

            # # Switch back to the original branch
            # git checkout "$branch"
            # echo "    Switched back to branch $branch."
        fi

        if [ "$branch" == "main" ]; then
            # Check if there are committed changes on the main branch
            if git log origin/main..HEAD | grep -q "."; then
                echo "    Committed changes found on main branch in $repo_dir"

                # Stash any uncommitted changes before switching branches
                git stash -u
                echo "    Uncommitted changes stashed from main branch."

                # Create a unique branch name for the bad-practice changes
                bad_practice_branch="bad-practice-$(date +%Y%m%d%H%M%S)"

                # Create and switch to the bad-practice branch
                git checkout -b "$bad_practice_branch"
                echo "    Switched to new branch $bad_practice_branch."

                # Apply the stashed changes, if any
                git stash pop
                echo "    Stashed changes applied to $bad_practice_branch."

                # Commit any stashed changes
                if [ -n "$(git status --porcelain)" ]; then
                    git add .
                    git commit -m "Bad-practice changes from main branch"
                    echo "    Bad-practice changes committed to $bad_practice_branch."
                fi

                # Push the bad-practice branch to the remote repository
                if ! remote_branch_exists "$bad_practice_branch" "$repo_dir"; then
                    git push --set-upstream origin "$bad_practice_branch"
                else
                    git push origin "$bad_practice_branch"
                fi
                echo "    Changes have been moved to and pushed on the $bad_practice_branch branch in $repo_dir."

                # Switch back to the main branch
                git checkout main
                echo "    Switched back to main branch."
            else
                echo "    No committed changes to push on the main branch in $repo_dir"
            fi
        else
            # Check if there are committed changes to push on the current branch
            if remote_branch_exists "$branch" "$repo_dir"; then
                if git log origin/"$branch"..HEAD | grep -q "."; then
                    echo "    Committed changes found on branch $branch in $repo_dir"
                    git push origin "$branch"
                    echo "    Changes have been pushed to remote branch $branch in $repo_dir"
                else
                    echo "    No committed changes to push on branch $branch in $repo_dir"
                fi
            else
                echo "    Remote branch $branch does not exist, pushing for the first time"
                git push --set-upstream origin "$branch"
            fi
        fi
    done

    # # Switch back to the original branch
    # git checkout "$original_branch"
    # echo "Switched back to the original branch $original_branch."

    cd - || return
}

# Export the functions so they can be used by find -exec
export -f push_committed_changes
export -f pull_all_branches
export -f is_blacklisted
export -f belongs_to_user
export -f remote_branch_exists

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
