# DayForge — one-stop release builds.
#
#   make            same as `make all`
#   make all        every artifact buildable on this machine (.apk + .deb
#                   here on Linux; .exe requires a Windows machine)
#   make apk        Android release APK        -> dist/
#   make deb        Debian/Ubuntu package      -> dist/
#   make exe        Windows release build      -> dist/ (Windows host only)
#   make version    print the version this build would produce
#   make test       flutter analyze + flutter test
#   make clean      remove build/ and dist/
#
# Cross-compilation is not supported by Flutter: each desktop target must be
# built on its own OS. `make all` builds what it can and says what it skipped.
#
# Every build is stamped (see "Versioning" below) and every target deletes
# its previous artifact *before* building, so a build that dies half way
# (the Android toolchain is memory-hungry — a killed Gradle run prints
# "Killed") can never leave a stale file behind pretending to be fresh.

FLUTTER ?= flutter
DIST    := dist

# ---------------------------------------------------------------- Versioning
# VERSION  marketing version, from pubspec.yaml            e.g. 1.0.0
# BUILD    Android versionCode: the commit count, so it
#          rises with every commit and installs upgrade    e.g. 13
# STAMP    what identifies *this* build: commit + sha,
#          plus a timestamp when the tree is dirty, so
#          two builds of edited code are never confused    e.g. 13.70eab8c.dirty2026-08-18-0912
# The stamp reaches the app through --dart-define (Settings → About shows it)
# and names the artifacts in dist/.
VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d+ -f1)
BUILD   := $(shell git rev-list --count HEAD 2>/dev/null || echo 1)
SHA     := $(shell git rev-parse --short HEAD 2>/dev/null || echo nogit)
# --porcelain, not `git diff`: a build containing brand-new (untracked) files
# is just as unreproducible as one with edits.
DIRTY   := $(shell test -z "$$(git status --porcelain 2>/dev/null)" || echo .dirty$(shell date +%Y-%m-%d-%H%M))
STAMP   := $(BUILD).$(SHA)$(DIRTY)
FULL    := $(VERSION)+$(STAMP)

# --build-name/--build-number set versionName/versionCode; BUILD_ID is read by
# lib/core/build_info.dart so the running app can say which build it is.
VERSION_ARGS := --build-name=$(VERSION) --build-number=$(BUILD) \
                --dart-define=APP_VERSION=$(VERSION) \
                --dart-define=BUILD_ID=$(STAMP)

# Android ABIs to ship. `make apk ABI=android-arm64` builds only 64-bit ARM:
# a third of the work and memory, and the right choice for any phone from the
# last decade — use it if a full build gets "Killed" on a small machine.
ABI ?=
ifeq ($(ABI),)
ABI_ARGS :=
else
ABI_ARGS := --target-platform=$(ABI)
endif

ifeq ($(OS),Windows_NT)
HOST := windows
else
HOST := $(shell uname -s | tr '[:upper:]' '[:lower:]')
endif

APK_OUT := build/app/outputs/flutter-apk/app-release.apk

.PHONY: all apk deb exe linux test version clean

all: apk deb exe
	@echo ""
	@echo "Done. Artifacts in $(DIST)/ (version $(FULL)):"
	@ls -lh $(DIST) 2>/dev/null || true

version:
	@echo "version:     $(VERSION)"
	@echo "versionCode: $(BUILD)"
	@echo "build id:    $(STAMP)"
	@echo "artifacts:   $(DIST)/dayforge-$(FULL).apk"
	@echo "             $(DIST)/dayforge_$(FULL)_amd64.deb"

apk:
ifeq ($(HOST),windows)
	$(FLUTTER) build apk --release $(VERSION_ARGS) $(ABI_ARGS)
	@if not exist $(DIST) mkdir $(DIST)
	copy /Y build\app\outputs\flutter-apk\app-release.apk $(DIST)\dayforge-$(FULL).apk
else
	@echo "apk: building $(FULL) (versionCode $(BUILD))"
	@rm -f $(APK_OUT) $(DIST)/dayforge-$(FULL).apk
	$(FLUTTER) build apk --release $(VERSION_ARGS) $(ABI_ARGS)
	@test -s $(APK_OUT) || { \
	  echo "apk: FAILED — no artifact at $(APK_OUT)."; \
	  echo "     If the log says 'Killed', the machine ran out of memory:"; \
	  echo "     close other apps, or build one ABI: make apk ABI=android-arm64"; \
	  exit 1; }
	@mkdir -p $(DIST)
	cp $(APK_OUT) $(DIST)/dayforge-$(FULL).apk
	@echo "apk: built $(DIST)/dayforge-$(FULL).apk"
endif

linux:
ifeq ($(HOST),linux)
	$(FLUTTER) build linux --release $(VERSION_ARGS)
else
	@echo "linux: skipped — Linux builds require a Linux machine."
endif

deb: linux
ifeq ($(HOST),linux)
	@mkdir -p $(DIST)
	@rm -f $(DIST)/dayforge_$(FULL)_amd64.deb
	bash tool/build_deb.sh $(FULL) $(DIST)
	@test -s $(DIST)/dayforge_$(FULL)_amd64.deb || { \
	  echo "deb: FAILED — no package produced."; exit 1; }
else
	@echo "deb: skipped — .deb packaging requires a Linux machine."
endif

exe:
ifeq ($(HOST),windows)
	$(FLUTTER) build windows --release $(VERSION_ARGS)
	@if not exist $(DIST) mkdir $(DIST)
	tar -a -c -f $(DIST)\dayforge-$(FULL)-windows.zip -C build\windows\x64\runner\Release .
	@echo exe: built $(DIST)\dayforge-$(FULL)-windows.zip (unzip and run advanced_todo.exe)
else
	@echo "exe: skipped — the Windows .exe must be built on a Windows machine"
	@echo "     (install Flutter there, then run: make exe)."
endif

test:
	$(FLUTTER) analyze
	$(FLUTTER) test

clean:
	$(FLUTTER) clean
	rm -rf $(DIST)
