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
#   make doctor     report the build's memory budget and this machine's RAM
#
# Cross-compilation is not supported by Flutter: each desktop target must be
# built on its own OS. `make all` builds what it can and says what it skipped.
#
# Every build is stamped (see "Versioning" below) and every target deletes
# its previous artifact *before* building, so a build that dies half way
# (the Android toolchain is memory-hungry — a killed Gradle run prints
# "Killed") can never leave a stale file behind pretending to be fresh.
#
# Memory: see "Containment" below. Builds run inside a capped cgroup so an
# overshoot kills the build and not your desktop session.

FLUTTER ?= flutter
DIST    := dist

ifeq ($(OS),Windows_NT)
HOST := windows
else
HOST := $(shell uname -s | tr '[:upper:]' '[:lower:]')
endif


# ---------------------------------------------------------------- Versioning
# The version is plain semver, MAJOR.MINOR.PATCH, set in pubspec.yaml:
#   MAJOR  breaking change — data model or sync format the old app can't read
#   MINOR  new feature, backwards compatible
#   PATCH  bug fix only
# Artifacts are named with that and nothing else: dayforge_1.0.0_amd64.deb.
#
# VERSION  marketing version, from pubspec.yaml            e.g. 1.0.0
# BUILD    Android versionCode: the commit count, so it
#          rises with every commit and installs upgrade    e.g. 13
# STAMP    full provenance — commit count + sha, plus a
#          timestamp when the tree is dirty                e.g. 13.70eab8c.dirty2026-08-18-0912
#
# STAMP does *not* go in the filename any more: it reaches the app through
# --dart-define, and Settings → About shows it. So a file you hand someone is
# named for its release, while the running app can still say exactly which
# build it is. `make version` prints both.
#
# ARTIFACT is what dist/ files are named for. A dirty tree gets a bare
# `-dirty` suffix — enough to stop an uncommitted build being handed out as a
# release, without the timestamp back in the name. Every target rm -f's its
# own artifact before building, so overwriting a same-named file is safe.
VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d+ -f1)
BUILD   := $(shell git rev-list --count HEAD 2>/dev/null || echo 1)
SHA     := $(shell git rev-parse --short HEAD 2>/dev/null || echo nogit)
# --porcelain, not `git diff`: a build containing brand-new (untracked) files
# is just as unreproducible as one with edits.
DIRTY   := $(shell test -z "$$(git status --porcelain 2>/dev/null)" || echo .dirty$(shell date +%Y-%m-%d-%H%M))
STAMP    := $(BUILD).$(SHA)$(DIRTY)
ARTIFACT := $(VERSION)$(if $(DIRTY),-dirty,)
FULL     := $(VERSION)+$(STAMP)

# --build-name/--build-number set versionName/versionCode; BUILD_ID is read by
# lib/core/build_info.dart so the running app can say which build it is.
VERSION_ARGS := --build-name=$(VERSION) --build-number=$(BUILD) \
                --dart-define=APP_VERSION=$(VERSION) \
                --dart-define=BUILD_ID=$(STAMP)

# --------------------------------------------------------------- Containment
# The Android build is the memory hog: Gradle's JVM, the Kotlin daemon and one
# gen_snapshot per ABI all peak together. On a machine with no swap the kernel
# picks a victim system-wide, and it is usually not the build — sessions have
# been logged out mid-`make all` (2026-08-19).
#
# So every build goes through tool/capped_build.sh, which puts a hard memory
# ceiling on the whole process tree. It is a script and not a bare
# `systemd-run --scope` here because Flutter is installed as a *classic snap*:
# `snap run` leaves the cgroup it was started in and takes a fresh scope of
# its own under app.slice, so a wrapper's ceiling would govern an empty cgroup
# while Gradle ran unbounded beside it. The script caps that scope too.
# `nice` keeps the other 11 cores' worth of work behind interactive processes
# so the machine stays usable while it compiles.
#
#   make apk MEM_MAX=6G     tighter ceiling on a busier machine
#   make apk CAP=           opt out entirely (CI, or a host without systemd)
#
# Default 8G: measured peak for a universal APK is ~4.3G inside the scope, and
# it leaves ~6G of this 14G machine for everything else.
MEM_MAX ?= 8G
NICE_LEVEL ?= 10
export MEM_MAX
export NICE_LEVEL
ifeq ($(HOST),windows)
CAP ?=
else
CAP ?= bash tool/capped_build.sh
endif

# Serialize: `make -j4 all` would otherwise run the Android and Linux builds
# at once and blow past the ceiling that makes any of this safe.
.NOTPARALLEL:

# ------------------------------------------------------------ Firebase config
# lib/firebase_options.dart and android/app/google-services.json are gitignored
# (they carry the AIza… project keys GitHub's scanner flags). A fresh clone has
# only the .template files, and Dart's error for the missing import is useless,
# so say it plainly before the toolchain starts.
FIREBASE_FILES := lib/firebase_options.dart android/app/google-services.json

.PHONY: firebase-check
firebase-check:
	@for f in $(FIREBASE_FILES); do \
	  test -f "$$f" || { \
	    echo "missing: $$f"; \
	    echo "  This file is gitignored — see manual-task.md M15. Either:"; \
	    echo "    flutterfire configure --project=advanced-todo-infinite"; \
	    echo "  or: cp $$f.template $$f  and fill in the API key."; \
	    exit 1; }; \
	done

# Android ABIs to ship. `make apk ABI=android-arm64` builds only 64-bit ARM:
# a third of the work and memory, and the right choice for any phone from the
# last decade — use it if a full build gets "Killed" on a small machine.
ABI ?=
ifeq ($(ABI),)
ABI_ARGS :=
else
ABI_ARGS := --target-platform=$(ABI)
endif

APK_OUT := build/app/outputs/flutter-apk/app-release.apk

.PHONY: all apk deb exe linux test version clean doctor

all: apk deb exe
	@echo ""
	@echo "Done. Artifacts in $(DIST)/ (version $(VERSION), build $(STAMP)):"
	@ls -lh $(DIST) 2>/dev/null || true

version:
	@echo "version:     $(VERSION)      (major.minor.patch, from pubspec.yaml)"
	@echo "versionCode: $(BUILD)"
	@echo "build id:    $(STAMP)   (in the app: Settings -> About)"
	@echo "artifacts:   $(DIST)/dayforge-$(ARTIFACT).apk"
	@echo "             $(DIST)/dayforge_$(ARTIFACT)_amd64.deb"
	@echo "             $(DIST)/dayforge-$(ARTIFACT)-windows.zip"
	@test -z "$(DIRTY)" || echo "" 
	@test -z "$(DIRTY)" || echo "NOTE: the tree is dirty, so artifacts carry the -dirty suffix."
	@test -z "$(DIRTY)" || echo "      Commit first for a release-named build."

apk: firebase-check
ifeq ($(HOST),windows)
	$(FLUTTER) build apk --release $(VERSION_ARGS) $(ABI_ARGS)
	@if not exist $(DIST) mkdir $(DIST)
	copy /Y build\app\outputs\flutter-apk\app-release.apk $(DIST)\dayforge-$(ARTIFACT).apk
else
	@echo "apk: building $(FULL) (versionCode $(BUILD)), memory ceiling $(MEM_MAX)"
	@rm -f $(APK_OUT) $(DIST)/dayforge-$(ARTIFACT).apk
	$(CAP) $(FLUTTER) build apk --release $(VERSION_ARGS) $(ABI_ARGS)
	@test -s $(APK_OUT) || { \
	  echo "apk: FAILED — no artifact at $(APK_OUT)."; \
	  echo "     'Killed' in the log means the $(MEM_MAX) ceiling was hit."; \
	  echo "     Cheapest fix, and right for any phone made this decade:"; \
	  echo "       make apk ABI=android-arm64      (~1/3 the AOT work and RAM)"; \
	  echo "     Or raise the ceiling if this machine has the headroom:"; \
	  echo "       make apk MEM_MAX=10G"; \
	  exit 1; }
	@mkdir -p $(DIST)
	cp $(APK_OUT) $(DIST)/dayforge-$(ARTIFACT).apk
	@echo "apk: built $(DIST)/dayforge-$(ARTIFACT).apk"
endif

linux: firebase-check
ifeq ($(HOST),linux)
	$(CAP) $(FLUTTER) build linux --release $(VERSION_ARGS)
else
	@echo "linux: skipped — Linux builds require a Linux machine."
endif

deb: linux
ifeq ($(HOST),linux)
	@mkdir -p $(DIST)
	@rm -f $(DIST)/dayforge_$(ARTIFACT)_amd64.deb
	bash tool/build_deb.sh $(ARTIFACT) $(DIST)
	@test -s $(DIST)/dayforge_$(ARTIFACT)_amd64.deb || { \
	  echo "deb: FAILED — no package produced."; exit 1; }
else
	@echo "deb: skipped — .deb packaging requires a Linux machine."
endif

exe: firebase-check
ifeq ($(HOST),windows)
	$(FLUTTER) build windows --release $(VERSION_ARGS)
	@if not exist $(DIST) mkdir $(DIST)
	tar -a -c -f $(DIST)\dayforge-$(ARTIFACT)-windows.zip -C build\windows\x64\runner\Release .
	@echo exe: built $(DIST)\dayforge-$(ARTIFACT)-windows.zip (unzip and run advanced_todo.exe)
else
	@echo "exe: skipped — the Windows .exe must be built on a Windows machine"
	@echo "     (install Flutter there, then run: make exe)."
endif

test:
	$(FLUTTER) analyze
	$(FLUTTER) test

doctor:
	@echo "host:            $(HOST)"
	@echo "memory ceiling:  $(MEM_MAX)  (make apk MEM_MAX=6G to tighten)"
	@echo "containment:     $(if $(CAP),$(CAP) at nice $(NICE_LEVEL),NONE — a runaway build can OOM the desktop)"
	@bash -c 'command -v systemd-run >/dev/null || echo "                 WARNING systemd-run missing: the ceiling cannot be enforced"'
	@echo "ABIs:            $(if $(ABI),$(ABI),all (universal APK) — ABI=android-arm64 is much cheaper)"
	@free -h 2>/dev/null | awk 'NR==1{print "                 "$$0} NR==2{print "RAM:             "$$2" total, "$$7" available"} /^Swap/{print "swap:            "$$2 ($$2=="0B"?"   <-- no swap: an overshoot has nowhere to spill":"")}'

clean:
	$(FLUTTER) clean
	rm -rf $(DIST)
