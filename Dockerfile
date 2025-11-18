# Custom Mastodon Dockerfile with theming support
# Use the upstream build stage for asset compilation
FROM ghcr.io/mastodon/mastodon:v4.5.1 AS build

# Switch to root to place theme files
USER root

# Create theming directories
RUN mkdir -p /mastodon/app/javascript/styles \
    && mkdir -p /mastodon/config/locales/custom

# Copy theme files directly - place in main styles directory like default themes
COPY theming/styles/ /mastodon/app/javascript/styles/
COPY theming/themes.yml /mastodon/config/themes.yml

# Copy custom locale overrides
COPY theming/locales/ /mastodon/config/locales/custom/

# Copy component overrides (strip the components/app/javascript prefix)
COPY components/app/javascript/ /mastodon/app/javascript/

# Install Node.js and enable Corepack for Yarn
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable

# Install Node.js dependencies
RUN yarn install --frozen-lockfile

# Compile assets including custom themes (skip environment loading)
RUN SECRET_KEY_BASE_DUMMY=1 \
    RAILS_CACHE_STORE=null \
    bundle exec rake assets:precompile RAILS_ENV=production

# Copy Vite-compiled theme assets to Rails assets directory
RUN cp -r /mastodon/public/packs/assets/* /mastodon/public/assets/ 2>/dev/null || true

# Final stage - copy compiled assets
FROM ghcr.io/mastodon/mastodon:v4.5.1

# Copy compiled assets from build stage
COPY --from=build /mastodon/public/assets /mastodon/public/assets
COPY --from=build /mastodon/public/packs /mastodon/public/packs

# Switch to root to copy theme files
USER root

# Copy theme files directly
# Copy theme files directly - place in main styles directory like default themes
COPY theming/styles/ /mastodon/app/javascript/styles/
COPY theming/themes.yml /mastodon/config/themes.yml

# Copy custom locale overrides
COPY theming/locales/ /mastodon/config/locales/custom/

# Copy view overrides
COPY views/ /mastodon/app/views/

# Fix ownership of db directory for schema.rb writes (needed for migrations)
RUN mkdir -p /opt/mastodon/db \
    && chown -R mastodon:mastodon /opt/mastodon/db || true

# Switch back to mastodon user
USER 991

# Preserve the original entrypoint from the base image
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

