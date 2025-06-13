# Branch Protection Setup (Run with GitHub CLI)

# Install GitHub CLI if not available
# https://cli.github.com/

# Set up main branch protection
gh api repos/wizzense/opentofu-lab-automation/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI/CD Pipeline"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false

echo "✅ Branch protection rules applied"
