// Narrow TCC target for the OpenTracks fork sync (same design as the other runners).
// This one exists because the job lived in crontab until 18.09 and cron cannot exec
// anything on /Volumes/SanDisk: the nightly died on `./gradlew: Operation not permitted`
// and took the v4.28.3 release with it. The script path is hardcoded so the Full Disk
// Access grant covers exactly this job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/opentracks-sync.sh";

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
