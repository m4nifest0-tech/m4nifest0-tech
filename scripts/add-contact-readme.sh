#!/usr/bin/env bash
set -e
OWNER="m4nifest0-tech"
CONTACT_EMAIL="m4nifest0-tech@m4nifest0.it"
repos=$(gh repo list "$OWNER" --limit 200 --json name,defaultBranchRef,isArchived,isFork -q '.[] | select(.isArchived==false and .isFork==false) | .name + "|" + (.defaultBranchRef.name // "main")')
echo "$repos" | while IFS='|' read -r repo branch; do
[ -z "$repo" ] && continue
echo "Checking $OWNER/$repo (branch: $branch)"
content=$(gh api "repos/$OWNER/$repo/contents/README.md?ref=$branch" -q '.content' 2>/dev/null | tr -d '\n' | base64 -d 2>/dev/null || true)
if [ -z "$content" ]; then
content="# $repo"
fi
if echo "$content" | grep -qF "$CONTACT_EMAIL"; then
echo "Contact already present, skipping"
continue
fi
new_content=$(printf '%s\n\n## Contact\n\nFor questions, issues or collaboration: %s\n' "$content" "$CONTACT_EMAIL")
sha=$(gh api "repos/$OWNER/$repo/contents/README.md?ref=$branch" -q '.sha' 2>/dev/null || true)
encoded=$(printf '%s' "$new_content" | base64 -w0)
if [ -n "$sha" ]; then
gh api --method PUT "repos/$OWNER/$repo/contents/README.md" -f message="Add contact section to README" -f content="$encoded" -f sha="$sha" -f branch="$branch" >/dev/null
else
gh api --method PUT "repos/$OWNER/$repo/contents/README.md" -f message="Add README with contact section" -f content="$encoded" -f branch="$branch" >/dev/null
fi
echo "Updated $repo"
done
