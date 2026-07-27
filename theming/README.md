# Theming

## Status: custom theming is currently disabled (as of Mastodon 4.6.4)

This directory used to ship two selectable themes, `domum-dark` and
`domum-light`, plus a shared `domum-social` palette. **They were removed
during the 4.5.13 -> 4.6.3 upgrade** because Mastodon 4.6 deleted the
per-theme SCSS system they were built on:

| Removed upstream in 4.6 | Our themes depended on it |
|---|---|
| `app/javascript/styles/mastodon/_functions.scss` | `@use '../mastodon/functions' as *;` |
| `app/javascript/styles/mastodon/css_variables.scss` | copied and re-declared wholesale |
| `styles/contrast.scss`, `styles/mastodon-light.scss` | referenced from our `themes.yml` |
| `$ui-base-color`, `$ui-highlight-color`, `$primary-text-color`, `$base-shadow-color`, ... | reassigned in `domum-{dark,light}.scss` |
| `--surface-*`, `--dropdown-*`, `--modal-*`, `--background-*` CSS vars | the entire body of our `css_variables.scss` |

The old files are archived, unmodified, at
`roles/mastodon/files/style-notes/domum-theme-4.5-archive/` — including the
brand icon set and the `_domum-variables.scss` colour palette. Nothing there
is wired into the build.

## What 4.6 does instead

`config/themes.yml` ships only `default: styles/application.scss`. Dark,
light and high-contrast are no longer themes — they are two independent user
settings, `color_scheme` (`auto|light|dark`) and `contrast` (`auto|high`),
which set `data-color-scheme` / `data-contrast` on `<html>`. Colours come
from CSS custom-property token layers in
`app/javascript/styles/mastodon/theme/`:

- `_base.scss` — `@mixin palette`, the raw ramps (`--color-grey-50..950`,
  `--color-indigo-50..950`, red/yellow/green)
- `_dark.scss` / `_light.scss` — `@mixin tokens` and `@mixin contrast-overrides`,
  mapping ramps onto semantic tokens (`--color-text-primary`,
  `--color-bg-brand-base`, `--color-border-primary`, ...)
- `index.scss` — applies them per `data-color-scheme` / `data-contrast`

## How to reinstate Domum branding

Do **not** write per-theme SCSS again. Add a single entrypoint that rides the
upstream token system:

```scss
// theming/styles/domum.scss
@use 'application';

// Overriding the ramps re-skins both colour schemes and both contrast
// levels at once, because every semantic token resolves through them.
html {
  --color-indigo-300: #ffd86b;  // $domum-glow-gold
  --color-indigo-500: #e0b84a;
  --color-grey-900:   #1c1f26;  // $domum-dark-charcoal
  --color-grey-950:   #111418;  // $domum-off-black
  // ...
}
```

and point `themes.yml` at it with `default: styles/domum.scss`. Keeping it as
`default` rather than adding a second theme avoids resurrecting the theme
dropdown, which now overlaps confusingly with the colour-scheme radios.

Palette values to draw from are in the archive's `_domum-variables.scss`.

Note the theme label i18n key moved: 4.6 looks up `I18n.t("themes.#{theme}")`,
not `settings.theme.*`.

## Interim branding without code

Site icon, thumbnail and `Setting.custom_css` are all editable from
Administration → Appearance, and cover most of what the themes did.

## What is still shipped from here

`locales/en.yml` is copied to `config/locales/custom/en.yml` by the
Dockerfiles. It carries the Devise failure strings that pair with
`initializers/username_login.rb`.
