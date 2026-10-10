CERT := VoiceInk Local Signing
FALLBACK_CERT := Developer ID Application: Developer Name

# The runners are signed with a stable identity, both for the same
# reason: each binary holds a Full Disk Access grant that lets its agent reach
# /Volumes/SanDisk. Ad-hoc signing produces a fresh cdhash on every rebuild, so
# macOS would see a different program and silently drop the grant — the agent
# would then die on "Operation not permitted" with nothing explaining why. A
# stable identity keeps the designated requirement, and the grant with it.
#
# The identity comes from the VoiceInk repo's scripts/create-local-signing-cert.sh
# (run by `make local-stable`). If it is ever missing from the keychain, the Developer
# ID key is used instead — it is stable in the way that matters here (identifier +
# team OU designated requirement) and is what the app bundles are re-signed with.
# Ad-hoc is the last resort, and it costs the grant.

RUNNERS := serho-runner

# serho-runner takes the two certificates in the opposite order, because it holds
# the grant everything else leans on: the bot, its tmux panes, and every agent
# running in them. create-local-signing-cert.sh deletes and re-mints "VoiceInk
# Local Signing" whenever find-identity so much as stumbles, and that would take
# this grant down with it. Nothing re-mints the Developer ID key.
serho-runner: CERT := Developer ID Application: Developer Name
serho-runner: FALLBACK_CERT := VoiceInk Local Signing

.PHONY: all clean
all: $(RUNNERS)

$(RUNNERS): %: %.c
	cc -O2 -Wall -Wextra -o $@ $<
	@NAME="$(CERT)"; \
	ID=$$(security find-identity -p codesigning 2>/dev/null | awk -v n="$(CERT)" 'index($$0, n) {print $$2; exit}'); \
	if [ -z "$$ID" ]; then \
		NAME="$(FALLBACK_CERT)"; \
		ID=$$(security find-identity -p codesigning 2>/dev/null | awk -v n="$(FALLBACK_CERT)" 'index($$0, n) {print $$2; exit}'); \
	fi; \
	if [ -n "$$ID" ]; then \
		codesign --force --sign "$$ID" --timestamp=none $@ && \
		echo "signed $@ with '$$NAME' — the Full Disk Access grant survives rebuilds"; \
	else \
		echo "WARNING: neither '$(CERT)' nor '$(FALLBACK_CERT)' is in the keychain;"; \
		echo "         $@ left ad-hoc. Re-grant Full Disk Access after every rebuild,"; \
		echo "         or run 'make local-stable' in the VoiceInk repo first."; \
	fi

clean:
	rm -f $(RUNNERS)
