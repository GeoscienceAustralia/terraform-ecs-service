FROM ubuntu:xenial

ARG DC_USER=ubuntu
ARG DC_TAG=datacube-1.5.2

# Upgrade and install dependencies
# Postgres is installed and configured in order to run integration tests
RUN apt-get update \
    && apt-get upgrade \
    && apt-get install -y wget bzip2 git postgresql gcc apt-utils sudo

RUN locale-gen en_US.UTF-8 en_US

# Add database configuration
ADD ./pg_hba.conf /tmp/.

# Initialise database
RUN /etc/init.d/postgresql start \
    && mv /tmp/pg_hba.conf $(su postgres -c 'psql -tAnc "show hba_file;"') \
    && su postgres -c 'createdb agdcintegration' \
    && su postgres -c 'createuser ubuntu -s'

# Create a new user account without a password
RUN adduser --disabled-password --gecos "" $DC_USER \
    && adduser $DC_USER sudo \
    && passwd -d $DC_USER

# Run user script
ADD ./user_setup.sh /tmp/user_setup.sh
RUN su $DC_USER -c "bash /tmp/user_setup.sh $DC_TAG"

SHELL ["/bin/bash", "-c"]
USER $DC_USER
