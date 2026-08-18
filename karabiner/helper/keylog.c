// Appends one JSON line per remapped keystroke: what was physically pressed and
// what Karabiner sent instead. Karabiner runs this from a `to.shell_command`, so
// it is on the keystroke path — a single exec, no shell pipeline, no date(1).
//
// Build: cc -O2 -o keylog keylog.c   (karabiner/build.sh does it automatically)
// Usage: keylog <physical-chord> <sent>

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

static void json_escape(const char *src, char *dst, size_t cap) {
    size_t j = 0;
    for (size_t i = 0; src[i] && j + 2 < cap; i++) {
        unsigned char c = (unsigned char)src[i];
        if (c == '"' || c == '\\') dst[j++] = '\\';
        else if (c < 0x20) continue;
        dst[j++] = (char)c;
    }
    dst[j] = '\0';
}

int main(int argc, char **argv) {
    if (argc < 3) return 1;

    const char *home = getenv("HOME");
    if (!home) return 1;

    struct timeval tv;
    gettimeofday(&tv, NULL);
    long long ms = (long long)tv.tv_sec * 1000 + tv.tv_usec / 1000;

    time_t secs = tv.tv_sec;
    struct tm lt;
    localtime_r(&secs, &lt);

    char path[1024];
    snprintf(path, sizeof path,
             "%s/Library/Application Support/Hammerspoon/InputLogger/physical-%04d-%02d.jsonl",
             home, lt.tm_year + 1900, lt.tm_mon + 1);

    int fd = open(path, O_WRONLY | O_CREAT | O_APPEND, 0600);
    if (fd < 0) return 1;

    char chord[256], sent[256], line[640];
    json_escape(argv[1], chord, sizeof chord);
    json_escape(argv[2], sent, sizeof sent);
    int n = snprintf(line, sizeof line,
                     "{\"ts\":%lld,\"chord\":\"%s\",\"sent\":\"%s\"}\n", ms, chord, sent);

    // one atomic append: O_APPEND writes under PIPE_BUF never interleave, which
    // matters because Karabiner fires these concurrently on fast key sequences
    ssize_t ignored = write(fd, line, (size_t)n);
    (void)ignored;
    close(fd);
    return 0;
}
