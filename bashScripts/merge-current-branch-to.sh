#/bin/bash
echo "Merges current branch to target branch, passed as comment, pushes and returns back"
TARGET_BRANCH=$1
SOURCE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo Target branch: $TARGET_BRANCH
echo Source branch: $SOURCE_BRANCH
git checkout "$TARGET_BRANCH" && git pull && git merge "$SOURCE_BRANCH" && git push && git checkout "$SOURCE_BRANCH"

