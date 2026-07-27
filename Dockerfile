# Custom Mastodon image: Domum overrides layered on the upstream release.
#
# Overlays: view overrides, validator overrides, JS/TSX component overrides,
# and a custom locale drop-in. Custom SCSS themes were removed for 4.6 --
# see theming/README.md.
#
# Node is installed from NodeSource because the published mastodon image has
# no node or yarn (upstream only copies them into its precompiler stage).
# Keep the major in step with upstream's .nvmrc.
#
# Use the upstream build stage for asset compilation
FROM ghcr.io/mastodon/mastodon:v4.6.4 AS build

# Switch to root to place override files
USER root

RUN mkdir -p /mastodon/config/locales/custom

# Copy custom locale overrides
COPY theming/locales/ /mastodon/config/locales/custom/

# Copy component overrides (strip the components/app/javascript prefix)
COPY components/app/javascript/ /mastodon/app/javascript/

# Copy validator overrides
COPY components/app/validators/ /mastodon/app/validators/

# Install Node.js and enable Corepack for Yarn
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable

# Install Node.js dependencies
RUN yarn install --immutable

# Compile assets including custom themes (skip environment loading)
RUN SECRET_KEY_BASE_DUMMY=1 \
    RAILS_CACHE_STORE=null \
    bundle exec rake assets:precompile RAILS_ENV=production

# Copy Vite-compiled theme assets to Rails assets directory
RUN cp -r /mastodon/public/packs/assets/* /mastodon/public/assets/ 2>/dev/null || true

# Final stage - copy compiled assets
FROM ghcr.io/mastodon/mastodon:v4.6.4

# Copy compiled assets from build stage
COPY --from=build /mastodon/public/assets /mastodon/public/assets
COPY --from=build /mastodon/public/packs /mastodon/public/packs

# Switch to root to copy override files
USER root

# Copy theme files directly
# Copy custom locale overrides
COPY theming/locales/ /mastodon/config/locales/custom/

# Copy view overrides
COPY views/ /mastodon/app/views/

# Copy validator overrides
COPY components/app/validators/ /mastodon/app/validators/

# Fix ownership of db directory for schema.rb writes (needed for migrations)
RUN mkdir -p /opt/mastodon/db \
    && chown -R mastodon:mastodon /opt/mastodon/db || true

# Switch back to mastodon user
USER 991

# Preserve the original entrypoint from the base image
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

