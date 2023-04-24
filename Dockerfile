FROM debian:11.6-slim

LABEL "com.github.actions.name"="Deploy WordPress"
LABEL "com.github.actions.description"="An action to deploy a WordPress project to a WP Engine site via git."
LABEL "com.github.actions.icon"="chevrons-right"
LABEL "com.github.actions.color"="blue"

RUN apt-get update && apt-get install -y git

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]