# docker — which compose stacks run on which machine

- `compose-projects.txt` (public) and `compose-projects.private.txt` (stacks kept out of the public dotfiles) are the registry: a stack dir per line — relative to `$HOME`, or absolute for a stack on an external drive — followed by the machines it runs on, by `scutil --get LocalHostName`. A machine named nowhere, including anyone else's, starts nothing.
- `up.sh` brings up the stacks listed for this machine that are not fully running (pull, build, up -d). Only services with a restart policy count as "should be running", so a job service (mma's scraper, run by launchd) never triggers a start. Missing dirs, e.g. an unplugged drive, are skipped. Run by install step 15 and by `up`; sources `~/.config/openai_key.sh` so compose variables resolve outside an interactive shell.
- `sync.sh` lists running stacks that neither registry knows. It does not edit the registry: which machines a stack belongs to is a person's call.
- `install/check.sh` checks that every stack listed for this machine is running.
- This dir defines no services itself; each stack keeps its own compose file and AGENTS.md (`litellm/`, `qdrant/`, `docker-logger/` here, the rest under `~/projects/services/` and elsewhere).
