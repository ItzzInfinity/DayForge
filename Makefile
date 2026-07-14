# Advanced To-Do — one-stop release builds.
#
#   make            same as `make all`
#   make all        every artifact buildable on this machine (.apk + .deb
#                   here on Linux; .exe requires a Windows machine)
#   make apk        Android release APK        -> dist/
#   make deb        Debian/Ubuntu package      -> dist/
#   make exe        Windows release build      -> dist/ (Windows host only)
#   make test       flutter analyze + flutter test
#   make clean      remove build/ and dist/
#
# Cross-compilation is not supported by Flutter: each desktop target must be
# built on its own OS. `make all` builds what it can and says what it skipped.

FLUTTER ?= flutter
VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d+ -f1)
DIST    := dist

ifeq ($(OS),Windows_NT)
HOST := windows
else
HOST := $(shell uname -s | tr '[:upper:]' '[:lower:]')
endif

.PHONY: all apk deb exe linux test clean

all: apk deb exe
	@echo ""
	@echo "Done. Artifacts in $(DIST)/:"
	@ls -lh $(DIST) 2>/dev/null || true

apk:
ifeq ($(HOST),windows)
	$(FLUTTER) build apk --release
	@if not exist $(DIST) mkdir $(DIST)
	copy /Y build\app\outputs\flutter-apk\app-release.apk $(DIST)\dayforge-$(VERSION).apk
else
	$(FLUTTER) build apk --release
	@mkdir -p $(DIST)
	cp build/app/outputs/flutter-apk/app-release.apk $(DIST)/dayforge-$(VERSION).apk
	@echo "apk: built $(DIST)/dayforge-$(VERSION).apk"
endif

linux:
ifeq ($(HOST),linux)
	$(FLUTTER) build linux --release
else
	@echo "linux: skipped — Linux builds require a Linux machine."
endif

deb: linux
ifeq ($(HOST),linux)
	@mkdir -p $(DIST)
	bash tool/build_deb.sh $(VERSION) $(DIST)
else
	@echo "deb: skipped — .deb packaging requires a Linux machine."
endif

exe:
ifeq ($(HOST),windows)
	$(FLUTTER) build windows --release
	@if not exist $(DIST) mkdir $(DIST)
	tar -a -c -f $(DIST)\dayforge-$(VERSION)-windows.zip -C build\windows\x64\runner\Release .
	@echo exe: built $(DIST)\dayforge-$(VERSION)-windows.zip (unzip and run advanced_todo.exe)
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
