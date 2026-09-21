# applesauce — APFS compression of read-mostly data

`compress.sh` (last step of `up`) compresses what `targets.sh` lists; every
write drops decmpfs, so SDK updates undo it.

- afsctool refuses files >2 GiB, hence applesauce.
- `-r 0.9`: at the 0.95 default marginal files grow from the xattr.
- `.dotnet/packs`, never `.dotnet` — compressed CoreCLR SIGKILLs every `dotnet`,
  signature still valid. Smoke-test runtimes that map their own images.
- Bundles: running ones skipped (SIGBUS); rest need App Management on the
  terminal, or applesauce silently does nothing.
- Bundles are globbed from `/Applications` and `~/Applications` (one level down
  too), not listed — installing or deleting an app needs no edit. Dropped by the
  glob: root-owned ones (App Store, pkg installers, Premiere), which want sudo
  rather than the App Management grant, so the "no write access" count now means
  only a missing TCC grant; and anything reached through a symlink, i.e. off on
  an external drive. Already-compressed bundles like Xcode cost a scan and
  report no new files — no reason to list exceptions.
