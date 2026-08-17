// Narrow TCC target for the Transmission fork sync (same design as
// telegram-desktop-sync-runner.c). The sync needs the repo on /Volumes/SanDisk
// (exec of build scripts fails from cron with EPERM) and the login keychain
// (re-sign with Developer ID), both LaunchAgent-only. The script path is
// hardcoded so the Full Disk Access grant covers exactly this job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/transmission-sync.sh";

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
