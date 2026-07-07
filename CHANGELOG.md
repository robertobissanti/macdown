# Changelog

All notable changes to this project are documented in this file.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased] — Toolchain & WKWebView modernization — 2026-07-07

Author: Roberto Bissanti ([@robertobissanti](https://github.com/robertobissanti))

This release is a modernization pass aimed at getting MacDown building and
running cleanly on current macOS/Xcode, as a first step towards Gatekeeper
compliance. The Markdown parser (Hoedown) is untouched.

### Security

- Fixed CVE-2019-12138 and CVE-2019-12173 (directory traversal / arbitrary
  program execution via a crafted link in a previewed document).
  `-openOrCreateFileForUrl:` used to hand any resolved, reachable local
  link target straight to `-[NSWorkspace openURL:]`, including `.app`
  bundles and other executables reached via an absolute `file://` path or
  `../` traversal — a malicious Markdown file could silently launch an
  arbitrary local application when its (disguised) link was clicked. Now
  checks the *resolved* file's UTI and refuses to open anything conforming
  to `public.application`/`public.executable`. Auto-created link targets
  (for links pointing at files that don't exist yet) are now also confined
  to the current document's own folder, closing the other half of
  CVE-2019-12138 (writing outside the document's directory via `../`).

### Changed

- Raised `MACOSX_DEPLOYMENT_TARGET` from 10.8 to 12.0 across all targets.
- Migrated the preview pane from the legacy, deprecated WebKit `WebView` to
  `WKWebView`. This touches navigation/policy delegates, JS↔native
  messaging (`WKScriptMessageHandler` replacing the old `WebScripting`
  bridge), scroll sync, zoom (`pageZoom` replacing a private API), MathJax
  completion signaling, printing, and word counting.
- Preview HTML is now loaded via `-loadFileURL:allowingReadAccessToURL:`
  from a hidden sidecar file written next to the open document
  (`.macdown-preview-<uuid>.html`, git-ignored), instead of
  `-loadHTMLString:baseURL:`. WKWebView restricts `file://` sub-resource
  loads to the loaded page's own directory, which broke custom user styles
  and arbitrarily-located local images under the old approach.
- Local stylesheets/scripts (custom user CSS, Prism, MathJax's init script)
  are now embedded inline in the generated HTML rather than linked, for the
  same file-access-restriction reason.
- Upgraded Sparkle from 1.x to 2.x (`SPUStandardUpdaterController` /
  `SPUUpdater`, EdDSA signing key instead of DSA, `use_frameworks!` in the
  Podfile). Auto-update testing needs a fresh EdDSA key pair generated via
  `Sparkle/bin/generate_keys` on the machine doing the signing.
- Bumped MASPreferences (1.3 → 1.4) and PAPreferences (0.4 → 0.5).
- Migrated `Tools/GitHub-style-generator` from `node-sass` (deprecated,
  native bindings) to `sass` (Dart Sass); updated its `Makefile` flags
  accordingly (`--include-path` → `--load-path`).
- Bumped the `cocoapods` gem constraint in `Gemfile`; dropped the dead
  `travis` gem (Travis CI is defunct for this project).
- Dropped the stale `Gemfile.lock` (pinned Bundler 1.17.3 / CocoaPods 1.10.1,
  both incompatible with current Ruby).
- README: updated build requirements (macOS SDK 12+, current Xcode) and
  added a "Notes on the WKWebView Preview Engine" section for contributors.
- Cleared the remaining deprecation warnings from a full build log
  (`buildIssue_70666.txt`), across our own source (not vendored/Pods code):
  - `MPDocument.m`: the CVE-2019-12138/12173 executable-type check now uses
    the `UniformTypeIdentifiers` `UTType` class instead of the deprecated
    CoreServices `kUTTypeApplication`/`kUTTypeExecutable`/`UTTypeConformsTo`;
    `NSSavePanel.allowedFileTypes` → `.allowedContentTypes` in the save,
    HTML-export, and PDF-export panels; `NSFileHandlingPanelOKButton` →
    `NSModalResponseOK`.
  - `MPToolbarController.m`: `NSToolbarItem.minSize`/`.maxSize` → Auto
    Layout width/height constraints on the toolbar item's view.
  - `MPEditorView.m`: `NSDragPboard` (a pasteboard-name constant, not a drag
    type) → `NSPasteboardTypeFileURL`.
  - `MPDocumentSplitView.m`: `colorUsingColorSpaceName:` →
    `colorUsingColorSpace:`.
  - `MPGeneralPreferencesViewController.m`: `NSOnState` →
    `NSControlStateValueOn`.
  - `MPUtilities.m`: `+[NSKeyedUnarchiver unarchiveObjectWithFile:]` →
    `+unarchivedObjectOfClasses:fromData:error:` with an explicit allowed-
    class set.
  - `macdown-cmd/main.m`: `stringByAddingPercentEscapesUsingEncoding:` →
    `stringByAddingPercentEncodingWithAllowedCharacters:`; the deprecated
    `launchAppWithBundleIdentifier:options:additionalEventParamDescriptor:
    launchIdentifier:` + `NSWorkspaceLaunchDefault` pair →
    `-openApplicationAtURL:configuration:completionHandler:`.
  - Several K&R-style C function declarations without `(void)` prototypes
    across `MPMainController.m`, `MPRenderer.m`, `MPUtilities.m`,
    `MPDocument.m`, and `macdown-cmd/main.m`.
- Podfile: added a `post_install` hook forcing every CocoaPods sub-target's
  `MACOSX_DEPLOYMENT_TARGET` up to 12.0. GBCli, handlebars-objc, hoedown,
  JJPluralForm, LibYAML, M13OrderedDictionary, MASPreferences, and
  PAPreferences all still shipped their own, much older deployment targets
  (as low as 10.6) that Xcode now warns about on every build.
- Podfile: extended the `post_install` hook to also rewrite hoedown's own
  headers (`Pods/hoedown/src/*.h` and the generated `hoedown-umbrella.h`)
  from quoted sibling includes (`#include "buffer.h"`) to angle-bracketed
  ones (`#include <hoedown/buffer.h>`). Harmless for a static library, but
  `use_frameworks!` builds hoedown as an actual Clang module framework,
  where Xcode flags the quoted form
  (`CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER`). hoedown is vendored
  and regenerated on every `pod install`, so this has to be a `post_install`
  patch rather than a direct edit. Generalized the hook into a reusable
  `patch_quoted_framework_includes` helper and applied it to
  PAPreferences-framework's umbrella header too (same warning, same fix).
- Not fixed: two Clang static-analyzer warnings ("Code will never be
  executed", "Variable 'hb_lval' may be uninitialized") inside
  handlebars-objc's Bison/Flex-generated parser files
  (`handlebars-objc.yy.m`, `y.tab.c`). These live in Xcode's DerivedData,
  regenerated from the pod's own grammar on every clean build — not part
  of this repo or even of the (gitignored) `Pods/` tree, so there's
  nothing here to durably patch. Upstream handlebars-objc issue.
- `MacDown.xcodeproj/project.pbxproj`: set `alwaysOutOfDate = 1` on the
  "Update Build Number", "Fetch Prism Resources", and "Transpile Styles"
  Run Script build phases (equivalent to unchecking "Based on dependency
  analysis" in Xcode). None of the three declare file outputs Xcode could
  use to detect staleness — "Update Build Number" in particular can't,
  since its output depends on git state, not on any input file — so they
  were always meant to run on every build; this just tells Xcode that
  explicitly instead of warning about it.
- `Dependency/peg-markdown-highlight/pmh_parser_head.c`: fixed a missing
  `(void)` prototype and rewrote two "assign via a comma operator inside a
  ternary" idioms as plain `if`/`else` (same behavior, no more "possible
  misuse of comma operator" warning). Note: the fixes had to go in
  `pmh_parser_head.c`, not the generated (and gitignored)
  `pmh_parser.c` — the Makefile combines `pmh_parser_head.c` +
  `pmh_parser_core.c` + `pmh_parser_foot.c` into `pmh_parser.c` on every
  build, so editing the generated file directly would've been overwritten.
- `Dependency/peg-markdown-highlight/pmh_styleparser.c`: five more missing
  `(void)` prototypes.
- `insertText:` (deprecated since macOS 10.11): converted the last 6 call
  sites (5 in `NSTextView+Autocomplete.m`, 1 in `MPDocument.m`) to
  `-insertText:replacementRange:`, passing `NSMakeRange(NSNotFound, 0)` —
  Apple's documented sentinel for "use the current selection or marked
  (IME composition) range", matching the old method's behavior exactly.
  Every other call site in both files already used the 2-arg form; these
  were the last stragglers.

### Fixed

- `Tools/update_build_number.sh`: unquoted `$(pwd -P)` broke the build when
  the checkout path contained a space (pre-existing bug, unrelated to this
  modernization pass).
- MathJax not rendering: the script tag was pointed at the bundled
  `MathJax.js`, which is only the bootstrap loader — the `config/`, `jax/`,
  `extensions/`, and `fonts/` subtrees it fetches relative to its own script
  URL at runtime were never vendored locally. Reverted to loading from the
  CDN, as it always effectively was even before this migration (a
  `WebResourceLoadDelegate` used to transparently swap just the bootstrap
  file's bytes for a local copy; WKWebView has no equivalent API, and the
  local copy isn't self-sufficient on its own).
- Print crashing (`EXC_BREAKPOINT` in `-printDocumentWithSettings:...`):
  `WKWebView`'s `-printOperationWithPrintInfo:` returns an operation whose
  view has no frame set; it must be sized to the paper explicitly before
  AppKit's printing machinery runs it.
- Preferences → Rendering: the whole pane had drifted out of alignment
  (overlapping rows for "Theme:"/"Accessory:", the syntax-highlighting
  checkbox, etc.). Root cause for "Graphviz"/"Mermaid" specifically: they
  used a `fixedFrame` (absolute position, untouched by Auto Layout) while
  the "Show line numbers" row they're meant to align with is
  constraint-driven, so any layout drift desynced them; converted to
  proper constraints. The rest of the pane's spacing was fixed by hand in
  Interface Builder.
- Image drag-and-drop into the editor: previously read the entire dropped
  file into memory and inlined it as
  `![](data:image/jpeg;base64,<...>)`, mislabeling every file as
  `image/jpeg` regardless of its real type and bloating the Markdown source
  with the full file contents on every drop. Now inserts a plain
  `![](path)` reference, for any image type.
- Preview images at an absolute path outside the document's own directory
  (e.g. a file dragged in from `~/Downloads`) failing to load — same root
  cause and fix as the custom-styles issue above.

### Added

- Preview images now always render at 100% of the preview pane's width
  (`img { width: 100% !important; }` in the base HTML template), regardless
  of the image's natural size.
- `.gitignore` entry for the preview sidecar file.

### Infrastructure

- Replaced `.travis.yml` with `.github/workflows/tests.yml` (GitHub
  Actions). The old Travis config pinned `osx_image: xcode10.1`, several
  major Xcode/macOS releases behind this project's current
  `MACOSX_DEPLOYMENT_TARGET`; Travis CI's free macOS build queue for open
  source projects has also been effectively dead for years, which is why
  the `continuous-integration/travis-ci` required status check on PRs
  never completes. Note: the required-checks list in this repo's branch
  protection settings still needs to be updated by a maintainer/admin to
  reference the new workflow instead — that's not something fixable from
  a PR.
- Verified the app already builds as a universal binary (arm64 + x86_64):
  no `ARCHS`/`VALID_ARCHS`/`EXCLUDED_ARCHS` overrides exist anywhere in
  the project, so it inherits Xcode's default `ARCHS_STANDARD`, and
  `ONLY_ACTIVE_ARCH = YES` is scoped to the Debug configuration only (as
  it should be) — Release/Archive builds already produce both
  architectures. No changes were needed here.

### Removed

- `DOMNode+Text.{h,m}`, `WebView+WebViewPrivateHeaders.h`,
  `MPMathJaxListener.{h,m}` — legacy WebView1-only code with no WKWebView
  equivalent, superseded by the changes above.

### Known Issues

- Preferences → Rendering: Interface Builder still marks several views in
  this pane `ambiguous`/`misplaced` in the saved xib, even though the pane
  renders correctly at runtime (verified). This looks like stale IB
  diagnostic state left over from manual editing rather than a real
  runtime issue; running Editor → Resolve Auto Layout Issues → Update All
  Frames in Xcode would clear it, but hasn't been done yet.
- A similar row-overlap was also reported in the "General" pane; it hasn't
  been looked at or fixed yet.
- Preferences → Markdown: Xcode reports 8 "Trailing constraint is missing"
  warnings across the extension checkbox groups. Traced these by hand:
  every flagged button's width is already fully determined transitively
  (tied to a sibling via equal-width + equal-leading, where that sibling
  does have an explicit trailing constraint), so this looks like the same
  class of IB false positive as the Rendering pane above — the checker
  doesn't trace equal-width chains when deciding whether a view's trailing
  edge is "missing". Not touched, since the layout renders correctly.
- Preferences → Editor: Xcode reports 4 "Fixed leading and trailing
  constraints with a center constraint may cause clipping" warnings. At
  least one is a real, pre-existing issue (not introduced this pass): the
  font-preview field (`g0N-qr-H8K`) has its leading edge pinned two
  different ways — once via its own row's label ("Base font:"), once via
  the theme popup button in the row below, whose position derives from a
  *different* label ("Theme:"). These only stay consistent if both labels
  happen to render at the same width, which nothing currently enforces.
  Needs a fix in Interface Builder with visual verification (adding an
  equal-width tie between the two labels, most likely) rather than a blind
  XML edit — left as a known issue for now.
- Gatekeeper compliance (notarization, Developer ID signing, hardened
  runtime + entitlements) is not yet done.
- Not yet cross-platform; this pass is macOS-only.
