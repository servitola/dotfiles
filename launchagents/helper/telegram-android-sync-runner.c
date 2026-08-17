// Narrow TCC target for the Telegram-Android fork sync (same design as
// voiceink-sync-runner.c — see the rationale there). The repo and gradle build
// live on /Volumes/SanDisk, unreachable from cron without a TCC grant. The
// script path is hardcoded so the Full Disk Access grant covers exactly this job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/telegram-android-sync.sh";

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
