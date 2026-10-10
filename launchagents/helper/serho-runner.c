// Narrow TCC target for the serho bot agent, and through it for every Claude
// pane the bot spawns.
//
// The problem it solves: the agent used to exec `/opt/homebrew/bin/uv` directly,
// so `uv` was the process TCC had to be granted Full Disk Access. That grant
// keeps disappearing, because the path it is really pinned to carries a version
// number — /opt/homebrew/Cellar/uv/<version>/bin/uv, which the `bin/uv` symlink
// resolves to. Every `brew upgrade uv` moves that path and orphans the grant,
// and the whole tree loses /Volumes/SanDisk and ~/Documents until someone walks
// through System Settings again. Re-signing uv does not help: a stable signature
// fixes a changing cdhash, not a changing path.
//
// So the grant moves onto this binary instead: a fixed path nothing upgrades,
// signed with a stable identity so it survives its own rebuilds. It forks rather
// than execs, which keeps it as the responsible process for everything below —
// uv, the bot, tmux panes, the agents in them — and they all inherit the grant.
//
// Same design as ~/projects/forks/runner/forks-runner.c, with one addition: the bot is a
// long-running daemon, so signals have to reach it. launchd signals the job's
// process group on stop, but `launchctl kill` and a stray `kill <pid>` address
// this process alone; without forwarding, the bot would outlive its runner and
// hold the Telegram connection as an orphan.
//
// Build: make -C dotfiles/launchagents/helper

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

// Kept byte-for-byte equivalent to what the plist used to run inline. The mkdir
// stays because launchd opens StandardOutPath before the bot's own Python mkdir
// can run; the `exec` keeps uv in this child's PID rather than adding a shell.
static const char *kCommand =
    "mkdir -p \"$HOME/Library/Logs/serho\"; "
    "exec /opt/homebrew/bin/uv run --directory /Users/servitola/projects/serho telegram-bot";

static volatile sig_atomic_t child_pid = 0;

static void forward(int sig) {
    if (child_pid > 0) {
        kill(child_pid, sig);
    }
}

int main(void) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        execl("/bin/zsh", "zsh", "-c", kCommand, (char *)NULL);
        perror("execl");
        _exit(127);
    }

    child_pid = pid;
    struct sigaction sa;
    sa.sa_handler = forward;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
    sigaction(SIGQUIT, &sa, NULL);

    int status = 0;
    while (waitpid(pid, &status, 0) < 0) {
        if (errno != EINTR) {
            perror("waitpid");
            return 1;
        }
    }

    // launchd's KeepAlive reads the exit status, so a crash has to look like a
    // crash from out here too.
    if (WIFSIGNALED(status)) {
        signal(WTERMSIG(status), SIG_DFL);
        raise(WTERMSIG(status));
    }
    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
