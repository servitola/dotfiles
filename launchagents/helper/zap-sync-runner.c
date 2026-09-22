// Narrow TCC target for the nightly Zap sync (same design as voiceink-sync-runner.c —
// see the rationale there). Two things force a LaunchAgent with its own grant instead
// of a crontab line: the checkout may live on /Volumes/SanDisk, where cron cannot exec
// build scripts (EPERM), and the install ends by re-signing with a Developer ID key
// from the login keychain, which the system-context crontab cannot reach. The script
// path is hardcoded so the Full Disk Access grant covers exactly this job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/zap-sync.sh";

int main(void) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        execl("/bin/zsh", "zsh", kScript, (char *)NULL);
        perror("execl");
        _exit(127);
    }
    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        perror("waitpid");
        return 1;
    }
    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
