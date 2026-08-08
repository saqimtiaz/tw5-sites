# Framework Dependencies and Build Architecture

## Overview

`tw5-sites` is the shared static-site framework used by multiple independent website repositories.

A site repository should depend on `tw5-sites` rather than independently managing the dependencies and build machinery required by the framework.

The intended dependency structure is:

```text
Site repository
└── tw5-sites
    ├── tiddlywiki
    └── secure-contact
```

For example:

```text
samtavisi/
└── node_modules/
    └── tw5-sites/
        ├── node_modules/
        │   ├── tiddlywiki/
        │   └── secure-contact/
        ├── plugins/
        ├── assets/
        └── build/
```

This keeps framework dependencies in the framework rather than requiring every site to declare them separately.

---

## Framework dependencies

The `tw5-sites` package declares the dependencies required to build a site.

For example:

```json
{
  "dependencies": {
    "tiddlywiki": "^5.4.1",
    "secure-contact": "^..."
  }
}
```

### TiddlyWiki

TiddlyWiki is a framework dependency because the framework's build process uses the TiddlyWiki CLI to render the static site.

The site itself does not need to declare `tiddlywiki` unless it directly uses the TiddlyWiki CLI or API outside the framework.

The framework build script should invoke the framework's own TiddlyWiki installation rather than relying on a globally installed version or the site's `node_modules`.

For example:

```bash
"$FRAMEWORK_ROOT/node_modules/.bin/tiddlywiki" \
  "${PLUGIN_ARGS[@]}" \
  "$SITE_ROOT" \
  --output "$OUT_DIR" \
  --render "$@"
```

This ensures that the framework controls the TiddlyWiki version used for builds.

---

## Secure Contact

`secure-contact` is also a framework dependency when every site using `tw5-sites` requires it.

The framework is responsible for copying its files into the generated site.

The build script should therefore locate it relative to the framework:

```bash
SECURE_CONTACT_DIR="$FRAMEWORK_ROOT/node_modules/secure-contact"
```

and copy the required files:

```bash
cp -r \
  "$SECURE_CONTACT_DIR/src/." \
  "$VENDOR_DIR/"
```

The consuming site does not need to know where `secure-contact` is installed.

The resulting generated site might contain:

```text
dist/
└── vendor/
    └── secure-contact/
        └── ...
```

This makes `secure-contact` an implementation detail of the framework.

---

## Site dependencies versus framework dependencies

A dependency should belong to `tw5-sites` when it is required by the framework or is part of the standard functionality provided to every site.

A dependency should remain in the site repository when it is specific to that site.

For example:

```text
tw5-sites
├── tiddlywiki
└── secure-contact

samtavisi
└── site-specific-dependency
```

If a site requires an additional TiddlyWiki plugin, it should not be necessary to modify `tw5-sites`.

Site-specific plugins can be loaded in addition to the framework plugins using the site's `plugins/` directory.

---

## Site-specific TiddlyWiki plugins

A site can provide additional TiddlyWiki plugins by placing them in its own:

```text
plugins/
```

directory.

For example:

```text
samtavisi/
├── plugins/
│   └── wine-data/
│       ├── plugin.info
│       └── ...
├── public/
├── ...
└── build.sh
```

The framework build process loads the framework's own plugins first and then loads the plugins found in the site's `plugins/` directory.

This allows a site to add functionality without modifying `tw5-sites`.

### Plugin layout

Each site-specific plugin should be a normal TiddlyWiki plugin directory containing its `plugin.info` and tiddler files.

For example:

```text
plugins/
└── wine-data/
    ├── plugin.info
    └── tiddlers/
        ├── ...
        └── ...
```

Multiple plugins can be provided:

```text
plugins/
├── wine-data/
│   ├── plugin.info
│   └── tiddlers/
└── reservations/
    ├── plugin.info
    └── tiddlers/
```

The framework build process should discover the immediate subdirectories of `plugins/` and add each one to the TiddlyWiki plugin search path.

Conceptually, the resulting plugin set is:

```text
Framework plugins
        +
Site plugins
        ↓
TiddlyWiki build
```

### Plugin dependencies installed through npm

A site may also install a TiddlyWiki plugin through npm if appropriate.

Such a dependency should not be loaded automatically merely because it exists in `node_modules`. The site should explicitly expose it to the build, either through the site's plugin configuration or another framework-supported mechanism.

This keeps plugin loading predictable and prevents unrelated npm packages from being treated as TiddlyWiki plugins.

### When to use a site-specific plugin

Use the site's `plugins/` directory when functionality is specific to one site.

For example:

* Custom widgets used only by one winery
* Site-specific TiddlyWiki macros
* Custom data handling
* Additional rendering functionality
* Components that are not appropriate for the shared framework

If the same functionality becomes useful to multiple sites, it can subsequently be moved into `tw5-sites`.

This provides a natural progression:

```text
Site-specific plugin
        │
        │ reused by multiple sites
        ▼
Framework plugin
```

---

## Build ownership

The framework owns the common build process.

The site repository should contain only a thin wrapper when necessary.

For example:

```text
samtavisi/build.sh
```

can contain:

```bash
#!/usr/bin/env bash
set -euo pipefail

SITE="samtavisi"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/node_modules/tw5-sites/build/build.sh" \
  "$SITE" \
  "$ROOT_DIR"
```

The corresponding `package.json` can simply contain:

```json
{
  "scripts": {
    "build": "./build.sh"
  }
}
```

The common build logic remains in:

```text
tw5-sites/build/build.sh
```

This means that changes to the common build process can be made once in `tw5-sites` and then consumed by all sites.

---

## Framework and site responsibilities

The framework is responsible for common functionality such as:

* Loading the common TiddlyWiki plugin
* Invoking TiddlyWiki
* Rendering site pages
* Generating `sitemap.xml`
* Generating `robots.txt`
* Copying framework assets
* Copying `secure-contact`
* Providing common JavaScript and CSS
* Other functionality shared by all sites

The site repository is responsible for:

* Site-specific TiddlyWiki content
* Site configuration
* Site-specific templates
* Site-specific CSS
* Site-specific images and other assets
* Site-specific plugins
* Other functionality unique to the site

---

## Static files

The site can place static files that should be copied unchanged into:

```text
public/
```

The framework build process copies the contents of this directory into the output directory.

For example:

```text
public/
├── favicon.ico
├── manifest.json
└── .well-known/
    └── verification-file
```

becomes:

```text
dist/
├── favicon.ico
├── manifest.json
└── .well-known/
    └── verification-file
```

This provides a simple extension mechanism without requiring changes to the framework build script.

---

## Site-specific build steps

The framework provides the standard build process but should not prevent a site from performing additional operations.

If a site requires unusual build steps, its `build.sh` can call the framework build first and then perform additional work.

For example:

```bash
#!/usr/bin/env bash
set -euo pipefail

SITE="winery-example"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/node_modules/tw5-sites/build/build.sh" \
  "$SITE" \
  "$ROOT_DIR"

# Site-specific post-processing
./scripts/generate-special-feed.sh
```

This keeps the common case centralized while allowing individual sites to extend the build when necessary.

---

## Dependency principle

The general rule is:

> A site should depend on the framework, and the framework should own the dependencies required to provide its functionality.

This avoids duplicating framework dependencies across every site while allowing each site to remain an independent repository.

The intended architecture is therefore:

```text
                    ┌──────────────────┐
                    │    Site A        │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │    tw5-sites     │
                    │                  │
                    │  TiddlyWiki      │
                    │  secure-contact  │
                    │  build system    │
                    │  shared assets   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ common framework │
                    └──────────────────┘

                    ┌──────────────────┐
                    │    Site B        │
                    └────────┬─────────┘
                             │
                             ▼
                       tw5-sites
```

Each site remains independent, while the common framework and its dependencies are maintained in one place.
