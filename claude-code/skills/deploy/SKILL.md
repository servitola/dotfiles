# Deploy Skill
1. Run all tests/linters for changed files
2. Sync changed scripts to server via scp/rsync
3. Restart affected services (systemd)
4. Verify service is running and responding
5. Commit with descriptive message if not already committed
