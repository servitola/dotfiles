---
name: obsidian
description: |
  Read, search, create, and edit notes in an Obsidian vault on the filesystem.

  Use when: "найди заметку в обсидиане", "создай заметку в obsidian", "search my obsidian vault", "add a note to obsidian"
---

# Obsidian Vault

Use this skill for filesystem-first Obsidian vault work: reading notes, listing notes, searching note files, creating notes, appending content, and adding wikilinks.

## Vault path

Use a known or resolved vault path before calling file tools.

The documented vault-path convention is the `OBSIDIAN_VAULT_PATH` environment variable. If it is unset, use `~/Documents/Obsidian Vault`.

File tools do not expand shell variables. Do not pass paths containing `$OBSIDIAN_VAULT_PATH` to Read, Write, Edit, or Grep; resolve the vault path first and pass a concrete absolute path. Vault paths may contain spaces, which is another reason to prefer file tools over shell commands.

If the vault path is unknown, Bash is acceptable for resolving `OBSIDIAN_VAULT_PATH` or checking whether the fallback path exists. Once the path is known, switch back to file tools.

## Read a note

Use Read with the resolved absolute path to the note. Prefer this over `cat` because it provides line numbers and pagination.

## List notes

Use Glob with the resolved vault path. Prefer this over `find` or `ls`.

- To list all markdown notes, use pattern `**/*.md` under the vault path.
- To list a subfolder, search under that subfolder's absolute path.

## Search

Use Grep for content searches and Glob for filename searches. Prefer these over `grep`, `find`, or `ls`.

- For filenames, use Glob with a filename pattern.
- For note contents, use Grep with the content regex as the pattern and `glob: "*.md"` when you want to restrict matches to markdown notes.

## Create a note

Use Write with the resolved absolute path and the full markdown content. Prefer this over shell heredocs or `echo` because it avoids shell quoting issues and returns structured results.

## Append to a note

Prefer a native file-tool workflow when it is not awkward:

- Read the target note with Read.
- Use Edit for an anchored append when there is stable context, such as adding a section after an existing heading or appending before a known trailing block.
- Use Write when rewriting the whole note is clearer than constructing a fragile edit.

For an anchored append with Edit, replace the anchor with the anchor plus the new content.

## Targeted edits

Use Edit for focused note changes when the current content gives you stable context. Prefer this over shell text rewriting.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, use these to link related content.
