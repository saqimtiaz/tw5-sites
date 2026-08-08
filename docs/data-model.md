# Site Publishing Data Model

This document defines the fields used by the static-site publishing system and the hierarchy between site, language, page, and template configuration.

## 1. Configuration hierarchy

The publishing system has four conceptual levels:

```text
Site
 ├── Language definitions
 ├── Site configuration
 │    ├── Header template
 │    └── Footer template
 │
 ├── Page
 │    └── Page-specific configuration
 │         └── Content template
 │
 └── Template
      └── Template-specific dependencies
```

The important distinction is between **inherited values** and **combined values**.

### Inherited values

For ordinary metadata, the effective value is resolved:

```text
Page → Site
```

The page value takes precedence. If the page does not define the field, the site value is used.

This is exposed through:

```text
.value[field]
```

### Source-specific values

To access only one level:

```text
.page.value[field]
.site.value[field]
```

Therefore:

```text
.value[description]
```

means:

> Get the effective description for this page.

While:

```text
.page.value[description]
```

means:

> Get the description defined specifically by this page.

And:

```text
.site.value[description]
```

means:

> Get the description defined by the site.

---

# 2. Field naming convention

All configuration fields use **camelCase**.

### Rules

* Start with a lowercase letter.
* Use camelCase for compound names.
* Do not use spaces.
* Do not use hyphens.
* Do not use underscores.
* Do not use colons.
* Use semantic names rather than names copied directly from an output format.

Examples:

```text
pageId
defaultLanguage
themeColor
ogTitle
ogDescription
ogImage
ogImageAlt
addressLocality
addressCountry
```

HTML and Schema.org naming conventions do not need to be reproduced in the TiddlyWiki field names.

For example:

```text
ogTitle
```

is converted by the generator to:

```html
<meta property="og:title">
```

---

# 3. Site configuration

Each website has one site configuration tiddler.

Example:

```text
title: $:/sites/samtavisi
tags: $:/tags/site-config

name: Samtavisi Marani
domain: https://samtavisimarani.com/

defaultLanguage: en
languages: en ka

author: Mamuka Kikvadze
themeColor: #f5efe8

ogImage: /images/samtavisi-open-graph.png
ogImageAlt: Samtavisi Marani Georgian wine
ogImageWidth: 1200
ogImageHeight: 630
ogImageType: image/png

phone: +995568500500

addressLocality: Samtavisi
addressRegion: Shida Kartli
addressCountry: GE

latitude: 42.012
longitude: 44.4071

instagram: https://www.instagram.com/samtavisi_marani/
```

## Site identity

| Field        | Purpose                          |
| ------------ | -------------------------------- |
| `name`       | Public name of the site/business |
| `domain`     | Canonical site origin            |
| `author`     | Default author                   |
| `themeColor` | Default browser theme color      |

## Language configuration

| Field             | Purpose                                                             |
| ----------------- | ------------------------------------------------------------------- |
| `defaultLanguage` | Language used as the site's default and `x-default` hreflang target |
| `languages`       | Languages supported by the site                                     |

`languages` declares what the site supports. It does not necessarily mean that every page exists in every language.

## Social metadata

| Field           | Purpose                           |
| --------------- | --------------------------------- |
| `ogImage`       | Default Open Graph image          |
| `ogImageAlt`    | Alternative text for the OG image |
| `ogImageWidth`  | OG image width                    |
| `ogImageHeight` | OG image height                   |
| `ogImageType`   | OG image MIME type                |

These may be overridden by individual pages when necessary.

## Business information

Fields such as:

```text
phone
addressLocality
addressRegion
addressCountry
latitude
longitude
```

describe the business/site and are normally inherited by every page.

## Site templates

The site configuration identifies the templates used for site-wide page components.

| Field            | Purpose                                       |
| ---------------- | --------------------------------------------- |
| `headerTemplate` | Tiddler containing the site's header template |
| `footerTemplate` | Tiddler containing the site's footer template |

For example:

```text
headerTemplate: $:/sites/samtavisi/templates/header
footerTemplate: $:/sites/samtavisi/templates/footer
```

These templates are used by the generic page template and allow each site to have its own header and footer without making the generic page template site-specific.

---

# 4. Language definitions

Language definitions are **global**, not site-specific.

A language tiddler describes a language itself.

Example:

```text
title: $:/languages/en
tags: $:/tags/language

language: en
locale: en_US
name: English
```

Another:

```text
title: $:/languages/ka
tags: $:/tags/language

language: ka
locale: ka_GE
name: ქართული
```

## Language fields

| Field      | Purpose                                    |
| ---------- | ------------------------------------------ |
| `language` | BCP 47 language code                       |
| `locale`   | Locale used for formats such as Open Graph |
| `name`     | Human-readable language name               |

Language definitions should contain facts about the language itself, not information about a particular website.

The site's `languages` field determines which global language definitions are available to that site.

For example:

```text
languages: en ka
```

causes the generator to resolve:

```text
$:/languages/en
$:/languages/ka
```

---

# 5. Page configuration

Every generated page has a page tiddler.

Example:

```text
title: en/index
tags: $:/tags/site-page

site: $:/sites/samtavisi
pageId: home
language: en
path: /

title: Samtavisi Marani | Georgian Natural Wines
description: Samtavisi Marani makes low-intervention Georgian wines from vineyards in Samtavisi, Georgia, with a deep respect for terroir, tradition and nature.
```

A Georgian translation might be:

```text
title: ka/index
tags: $:/tags/site-page

site: $:/sites/samtavisi
pageId: home
language: ka
path: /ge/

title: ...
description: ...
```

## Identity fields

| Field      | Purpose                                       |
| ---------- | --------------------------------------------- |
| `site`     | Identifies the site to which the page belongs |
| `pageId`   | Logical identity shared by translations       |
| `language` | Language of this particular page              |
| `path`     | Public URL path of the page                   |

### `pageId`

`pageId` identifies the conceptual page independently of language and URL.

For example:

```text
English:
pageId: story
path: /story.html

Georgian:
pageId: story
path: /ge/istoria.html
```

These are translations because they share:

```text
site
pageId
```

They do not need to share the same slug or path.

### `path`

`path` represents the **public URL**, not necessarily the filesystem output path.

For example:

```text
path: /
```

may be generated into:

```text
/en/index.html
```

depending on the site's build configuration.

## Page content template

A page may specify which template is responsible for rendering its content.

| Field             | Purpose                                        |
| ----------------- | ---------------------------------------------- |
| `contentTemplate` | Tiddler containing the page's content template |

For example:

```text
contentTemplate: $:/sites/samtavisi/templates/pages/home
```

This allows the generic page template to remain independent of the site's specific page designs.

---

# 6. Template hierarchy

The publishing system uses a generic page template as the outer document structure.

The generic page template is responsible for the overall HTML document:

```text
$:/templates/page
```

It does not contain site-specific header, footer, or page-content implementation.

Conceptually:

```text
$:/templates/page
    │
    ├── head
    │
    ├── site.headerTemplate
    │
    ├── page.contentTemplate
    │
    └── site.footerTemplate
```

The resulting hierarchy is:

```text
Generic page template
        │
        ├── Head template
        │
        ├── Site header template
        │
        ├── Page content template
        │
        └── Site footer template
```

### Generic page template

The generic page template is shared by all sites.

It knows only how to assemble the page:

```text
head
header
content
footer
```

It must not contain references specific to a particular winery or site.

### Site header and footer

The site configuration specifies:

```text
headerTemplate
footerTemplate
```

For example:

```text
headerTemplate: $:/sites/samtavisi/templates/header
footerTemplate: $:/sites/samtavisi/templates/footer
```

Another site can specify completely different templates while continuing to use the same generic page template.

### Page content

The page configuration specifies:

```text
contentTemplate
```

For example:

```text
contentTemplate: $:/sites/samtavisi/templates/pages/home
```

Different pages can therefore have different content structures while sharing the same site header, footer, and generic document structure.

### Resulting architecture

```text
                         $:/templates/page
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
              Head            Header          Footer
                                │               │
                         site.headerTemplate  site.footerTemplate

                                │
                                ▼
                         Page content
                                │
                         page.contentTemplate
```

The head template is reusable independently of the site-specific header, content, and footer templates.

---

# 7. Page metadata

Page-specific metadata may include:

```text
title
description

ogTitle
ogDescription
ogImage
ogImageAlt

twitterTitle
twitterDescription
twitterImage
```

These fields should only be specified when the page needs to override the site default.

For example, if the site has:

```text
ogImage: /images/default-og.png
```

most pages need no `ogImage` field.

A particular page can override it:

```text
ogImage: /images/wines/saperavi-og.png
```

The effective value is then:

```text
.value[ogImage]
```

which resolves:

```text
page.ogImage
    ↓ if absent
site.ogImage
```

---

# 8. Derived metadata

Some values should **not** be stored in page configuration because they can be calculated by the generator.

Examples:

```text
canonicalUrl
hreflang
ogLocale
ogLocaleAlternate
```

The generator derives these from the site's domain, page path, language, and translation relationships.

For example:

```text
domain:
https://samtavisimarani.com/

path:
/story.html
```

produces:

```text
https://samtavisimarani.com/story.html
```

The canonical URL therefore does not need to be stored separately.

---

# 9. Translation relationships

Translations are discovered using:

```text
site + pageId
```

For example:

```text
site: $:/sites/samtavisi
pageId: story
```

may return:

```text
en/story
ka/story
```

The custom filter function:

```text
.translations[]
```

returns the other pages belonging to the same translation group.

Conceptually:

```text
current page
    ↓
same site
    +
same pageId
    +
different page
```

The function should not depend on matching filenames or slugs.

---

# 10. Hreflang generation

Hreflang is generated automatically.

The generator:

1. Gets the current page's `site`.
2. Gets its `pageId`.
3. Finds all translations using `.translations[]`.
4. Gets each translation's `language`.
5. Gets each translation's `path`.
6. Combines each path with the site's `domain`.
7. Generates one `hreflang` link for each available translation.
8. Finds the page matching `site.defaultLanguage`.
9. Uses that page's URL as `x-default`.

For example:

```html
<link rel="alternate"
      hreflang="en"
      href="https://samtavisimarani.com/story.html">

<link rel="alternate"
      hreflang="ka"
      href="https://samtavisimarani.com/ge/story.html">

<link rel="alternate"
      hreflang="x-default"
      href="https://samtavisimarani.com/story.html">
```

The `x-default` URL is therefore derived from:

```text
site.defaultLanguage
```

rather than being stored independently.

---

# 11. Assets and `<head>` dependencies

Site and page configuration may declare resources that need to be included in the generated `<head>`.

## Site-wide resources

```text
stylesheets
scripts
```

These are included on every page.

Example:

```text
scripts: /js/site.js
stylesheets: /css/site.css
```

## Page-specific resources

A page may add additional resources:

```text
scripts: /js/wines.js
stylesheets: /css/wines.css
```

The generated page receives:

```text
site resources
+
page resources
```

This is **additive**, not fallback-based.

Unlike metadata:

```text
.value[field]
```

a page having a `scripts` field does not replace the site's scripts.

---

# 12. Template dependencies

Templates may eventually declare their own dependencies.

The final set of resources for a page can therefore be:

```text
site dependencies
+
template dependencies
+
page dependencies
```

For example:

```text
Site:
    /js/site.js

Wine template:
    /js/wine-cards.js

Wine page:
    /js/wine-gallery.js
```

The generated page includes all three.

Template dependencies should be introduced when multiple templates actually require them. They do not need to be implemented initially.

---

# 13. Structured data

JSON-LD is generated rather than manually copied into each page.

The generated structured data can combine:

```text
site information
+
page information
+
optional page-specific entities
```

The site configuration supplies information about the winery:

```text
name
domain
telephone
address...
geo...
founder
sameAs
```

The page configuration supplies information about the page:

```text
title
description
language
path
```

The generator derives relationships such as:

```text
WebPage → about → Winery
```

Specialized pages may eventually provide additional structured data, such as information about an individual wine.

---

# 14. Value resolution

The standard value lookup is:

```text
.value[field]
```

It resolves:

```text
page field
    ↓
site field
```

The source-specific lookups are:

```text
.page.value[field]
.site.value[field]
```

Therefore:

```text
.value[description]
```

means the effective description.

```text
.page.value[description]
```

means the page's explicitly defined description.

```text
.site.value[description]
```

means the site's explicitly defined description.

This mechanism should be used for ordinary metadata and configuration values.

It should **not** be used for additive collections such as `scripts` and `stylesheets`.

---

# 15. Configuration principles

The publishing system follows these principles:

### Store facts, derive relationships

Store:

```text
language
pageId
path
domain
```

Derive:

```text
canonical URL
hreflang
x-default
translation relationships
```

### Avoid duplication

If information applies to the entire site, store it once in site configuration.

If information applies to a language globally, store it in the global language definition.

If information applies only to one page, store it in the page configuration.

### Page overrides site

For ordinary values:

```text
page → site
```

The page value wins.

### Resources are additive

For resources:

```text
site + template + page
```

All applicable resources are included.

### Keep output-format naming separate

Internal fields use the project's camelCase convention.

The generator translates them into the appropriate HTML, Open Graph, Schema.org, or other output format.

For example:

```text
ogImage
```

becomes:

```html
<meta property="og:image">
```

The internal data model should not be forced to mirror the output format.
