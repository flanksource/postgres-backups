FROM ubuntu:18.04
#LABEL maintainer="Team ACID @ Zalando <team-acid@zalando.de>"

ENV RESTIC_VERSION=0.12.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  bsdmainutils \
  apt-utils \
  ca-certificates \
  lsb-release \
  gnupg \
  curl \
  jq \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && cat /etc/apt/sources.list.d/pgdg.list \
  && curl --silent https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install --no-install-recommends -y  \
  postgresql-client-12  \
  postgresql-client-11  \
  postgresql-client-10  \
  postgresql-client-9.6 \
  postgresql-client-9.5 \
  barman \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && curl -sSLo - https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 | bzip2 -dc > /usr/bin/restic \
  && chmod +x /usr/bin/restic

COPY dump.sh ./
COPY restore.sh ./
COPY list.sh ./

ENV PG_DIR=/usr/lib/postgresql

ENTRYPOINT ["/dump.sh"]
