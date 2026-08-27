FROM ghcr.io/open-webui/open-webui:main

# Open WebUI's startup wipes /app/backend/open_webui/static/* and
# rebuilds it from /app/build/static/*, so a plain COPY of custom.css
# is destroyed before any request is served. Solution:
#
#   1. Drop the CSS into /app/polish-theme/custom.css (a directory
#      OWUI does not touch).
#   2. Wrap OWUI's start.sh with our own /app/start-polish.sh that
#      re-copies our CSS into STATIC_DIR after OWUI's wipe, then
#      execs the real start.sh.
#
# Net effect: /static/custom.css ends up with our 20 KB of CSS on
# every container start.

COPY custom.css /app/polish-theme/custom.css
COPY start-polish.sh /app/start-polish.sh
RUN chmod +x /app/start-polish.sh

ENTRYPOINT ["/app/start-polish.sh"]
CMD ["bash", "start.sh"]
