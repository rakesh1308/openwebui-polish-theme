# Template Dockerfile — DO NOT use directly. build.sh generates
# the real Dockerfile from this template by inlining custom.css
# into the CUSTOM_CSS env var.

FROM ghcr.io/open-webui/open-webui:main

# CUSTOM_CSS is read by Open WebUI's backend at runtime and inlined
# into every HTML response. We bake it into the image so users
# don't need to pass any env vars.
ENV CUSTOM_CSS=__CUSTOM_CSS_PLACEHOLDER__
