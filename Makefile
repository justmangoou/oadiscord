PLUGIN_ID   := me.amankhanna.oadiscord
BINARY      := oadiscord
TARGET      := $(shell rustc -vV 2>/dev/null | sed -n 's/^host: //p')
PLUGIN_DIR  := $(PLUGIN_ID).sdPlugin
DIST        := dist/$(PLUGIN_DIR)
INSTALL_DIR := $(HOME)/.config/opendeck/plugins/$(PLUGIN_DIR)

PI_SRCS   := $(shell find pi/src -type f) \
             pi/package.json pi/svelte.config.ts pi/vite.config.ts pi/tsconfig.json
RUST_SRCS := $(shell find src -type f -name '*.rs') Cargo.toml

.PHONY: all pi binary bundle zip install clean

all: bundle

# Build SvelteKit property inspectors → assets/pi/
# version.json is always written by the SvelteKit build, so it serves as the sentinel.
assets/pi/version.json: $(PI_SRCS)
	cd pi && deno task build

pi: assets/pi/version.json

# Build Rust binary
target/release/$(BINARY): $(RUST_SRCS)
	cargo build --release

binary: target/release/$(BINARY)

# Assemble the full plugin directory in dist/
bundle: assets/pi/version.json target/release/$(BINARY)
	rm -rf $(DIST)
	cp -r assets/ $(DIST)
	cp target/release/$(BINARY) $(DIST)/$(BINARY)-$(TARGET)

# Create an importable ZIP for OpenDeck
zip: bundle
	cd dist && zip -r $(PLUGIN_ID).zip $(PLUGIN_DIR)/
	@echo "Created dist/$(PLUGIN_ID).zip"

# Install directly into the OpenDeck plugins directory
install: bundle
	rm -rf $(INSTALL_DIR)
	cp -r $(DIST) $(INSTALL_DIR)
	@echo "Installed to $(INSTALL_DIR)"

clean:
	rm -rf dist/ assets/pi/ target/
