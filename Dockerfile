FROM node:latest AS jsbuilder
WORKDIR /srv/rapidpro
RUN chown node:node -R /srv/rapidpro
USER node
COPY --chown=node package.json package-lock.json ./
RUN cd /srv/rapidpro && npm install


FROM python:3-buster AS base
RUN adduser --uid 1000 --disabled-password --gecos '' --home /srv/rapidpro rapidpro
WORKDIR /srv/rapidpro
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
        && apt-get -yq update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                unattended-upgrades \
                # rapidpro dependencies
                libgdal20 \
                nodejs \
        && npm install less -g \
        && npm install coffeescript -g \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean


FROM base AS pybuilder
ENV PATH=/srv/rapidpro/.local/bin/:$PATH
# Turns off writing .pyc files; superfluous on an ephemeral container.
ENV PYTHONDONTWRITEBYTECODE=1
# Seems to speed things up
ENV PYTHONUNBUFFERED=1
WORKDIR /srv/rapidpro
RUN apt-get -yq update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                build-essential \
                # CFFI deps
                libffi-dev \
                libssl-dev \
                # psycopg2 deps
                libpq-dev \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean
COPY --chown=rapidpro pip-requires.txt ./
USER rapidpro
RUN pip install --no-cache-dir --user -r pip-requires.txt


FROM base AS rapidpro
ENV PATH=/srv/rapidpro/.local/bin/:$PATH
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /srv/rapidpro/rapidpro
COPY --chown=rapidpro --from=jsbuilder /srv/rapidpro/node_modules/ ./node_modules/
COPY --chown=rapidpro --from=pybuilder /srv/rapidpro/.local /srv/rapidpro/.local
COPY --chown=rapidpro . /srv/rapidpro/rapidpro/
USER rapidpro
EXPOSE 8000
ENTRYPOINT ["/srv/rapidpro/rapidpro/entrypoint"]
