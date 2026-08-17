// Narrow TCC target for the VoiceInk upstream sync.
//
// The sync needs two things macOS hands out to different contexts:
//   - the login keychain (to codesign with "VoiceInk Local Signing"), which a
//     crontab job cannot reach — it runs from a LaunchDaemon with no user session;
//   - the repo on /Volumes/SanDisk, which a LaunchAgent cannot read without a
//     Removable Volumes / Full Disk Access grant.
//
// So the job has to be a LaunchAgent, and something has to hold the TCC grant.
// Granting it to /bin/zsh would hand Full Disk Access to every zsh script on the
// machine. This binary exists so the grant has exactly one narrow owner: it does
// nothing but spawn the sync script and return its exit status. Children inherit
// the responsible-process attribution, so the grant covers the whole job.
//
// Build: make -C dotfiles/launchagents/helper

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *kScript =
    "/Users/servitola/projects/dotfiles/cron/scripts/voiceink-upstream-sync.sh";

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
