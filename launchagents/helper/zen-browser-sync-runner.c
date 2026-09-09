// Narrow TCC target for the weekly Zen Browser rebuild (same design as
// voiceink-sync-runner.c — see the rationale there). The checkout and the whole build
// tree live on /Volumes/SanDisk, which the system-context crontab cannot even read:
// every Sunday since the drive got its TCC gate the job logged "volume mounted but
// unreadable (TCC) — skip" and built nothing. The script path is hardcoded so the Full
// Disk Access grant covers exactly this job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/zen-browser-sync.sh";

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
