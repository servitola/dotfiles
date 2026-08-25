# applesauce — APFS compression of read-mostly data

`compress.sh` (last step of `up`) compresses what `targets.sh` lists; every
write drops decmpfs, so SDK updates undo it.

- afsctool refuses files >2 GiB, hence applesauce.
- `-r 0.9`: at the 0.95 default marginal files grow from the xattr.
- `.dotnet/packs`, never `.dotnet` — compressed CoreCLR SIGKILLs every `dotnet`,
  signature still valid. Smoke-test runtimes that map their own images.
- Bundles: running ones skipped (SIGBUS); rest need App Management on the
  terminal, or applesauce silently does nothing.
- Absent on purpose: Premiere (root-owned), Xcode (ships compressed).
