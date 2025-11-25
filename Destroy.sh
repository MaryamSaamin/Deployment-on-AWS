# ------------------------------------------------------------
# Flask CDK Destroy Script
# Destroys all AWS resources created by CDK
# and cleans local environment, caches, and large files.
# ------------------------------------------------------------

set -euo pipefail

PROJECT_NAME="flask-cdk"
AWS_REGION="${AWS_REGION:-eu-north-1}"

echo "Starting CDK destroy process for project: ${PROJECT_NAME}"
echo "=========================================================="

# === Step 1: Confirm destroy ===
read -p "This will delete all AWS resources created by your CDK stack. Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Destroy aborted by user."
  exit 0
fi

# === Step 2: Navigate to project directory if exists ===
if [ -d "$PROJECT_NAME" ]; then
  cd "$PROJECT_NAME"
else
  echo "Project folder '$PROJECT_NAME' not found — continuing cleanup anyway."
fi

# === Step 3: Destroy CDK stack ===
echo "Destroying AWS CDK stack..."
cdk destroy --force

echo "AWS resources deleted successfully."

# === Step 4: Show current disk usage ===
echo
echo "Current disk usage before cleanup:"
df -h
echo

# === Step 5: Remove Python caches and temporary files ===
echo "Removing Python cache and temporary files..."
find ~/.cache -type f -delete || true
find ~/.local -type f -delete || true
find . -type d -name "__pycache__" -exec rm -rf {} + || true

# === Step 6: Remove virtual environments ===
echo "Removing virtual environments..."
rm -rf .env venv cdk-env || true

# === Step 7: Remove node_modules (if any) ===
echo "Removing node_modules folders..."
find . -name "node_modules" -type d -prune -exec rm -rf '{}' + || true

# === Step 8: Clear pip and npm caches ===
echo "Clearing pip and npm caches..."
pip cache purge || true
npm cache clean --force || true

# === Step 9: Check disk space again ===
echo
echo "Disk usage after cleanup:"
df -h /home/cloudshell-user || df -h
echo

# === Step 10: Optional full cleanup ===
read -p "Do you also want to delete project folders (flask-cdk, cdk.out, __pycache__)? (y/N): " fullclean
if [[ "$fullclean" =~ ^[Yy]$ ]]; then
  echo "Performing full cleanup..."
  cd ~ || true
  rm -rf flask-cdk cdk.out __pycache__
  echo "Project directories deleted."
else
  echo "Skipped full project deletion."
fi

echo
echo "Cleanup complete! Your environment is reset."
