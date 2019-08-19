# Start declaration of Build-Arg to determine where the image is getting built (DevOps agents or local)
ARG AGENTBUILD
ARG PYTHON_BASE_TAG
ARG PHP_BUILD_BASE_TAG
FROM buildpack-deps:stretch AS main
# End declaration of Build-Arg to determine where the image is getting built (DevOps agents or local)

# Configure locale (required for Python)
# NOTE: Do NOT move it from here as it could have global implications
ENV LANG C.UTF-8

# Install basic build tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        jq \
        make \
        unzip \
        # The tools in this package are used when installing packages for Python
        build-essential \
        # Required for Microsoft SQL Server
        unixodbc-dev \
        # Required for PostgreSQL
        libpq-dev \
        # Required for mysqlclient
        default-libmysqlclient-dev \
        # Required for .NET Core 1.1
        libunwind8 \
        # Required for ts
        moreutils \
        rsync \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core
FROM main AS dotnet-install

ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
	NUGET_XMLDOC_MODE=skip \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
	NUGET_PACKAGES=/var/nuget

COPY build/__dotNetCoreSdkVersions.sh /tmp
COPY build/__dotNetCoreRunTimeVersions.sh /tmp
COPY images/build/installDotNetCore.sh /tmp
COPY images/build/installDotNetCoreSdk.sh /tmp
RUN chmod +x /tmp/installDotNetCoreSdk.sh
RUN chmod +x /tmp/installDotNetCore.sh
RUN /tmp/installDotNetCore.sh

# Install Node.js, NPM, Yarn
FROM main AS node-install
COPY build/__nodeVersions.sh /tmp
RUN chmod a+x /tmp/__nodeVersions.sh
COPY images/build/installNode.sh /tmp
RUN chmod +x /tmp/installNode.sh
COPY images/receivePgpKeys.sh /tmp/scripts/receivePgpKeys.sh
RUN chmod +x /tmp/scripts/receivePgpKeys.sh
RUN /tmp/installNode.sh

###
# Python intermediate stages
# Docker doesn't support variables in `COPY --from`, so we're using intermediate stages
###
FROM mcr.microsoft.com/oryx/python-build-base:2.7-${PYTHON_BASE_TAG} AS py27-build-base
FROM mcr.microsoft.com/oryx/python-build-base:3.6-${PYTHON_BASE_TAG} AS py36-build-base
FROM mcr.microsoft.com/oryx/python-build-base:3.7-${PYTHON_BASE_TAG} AS py37-build-base
FROM mcr.microsoft.com/oryx/python-build-base:3.8-${PYTHON_BASE_TAG} AS py38-build-base
###
# End Python intermediate stages
###

FROM main AS python
# It's not clear whether these are needed at runtime...
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        tk-dev \
        uuid-dev \
 && rm -rf /var/lib/apt/lists/*
# https://github.com/docker-library/python/issues/147
ENV PYTHONIOENCODING UTF-8
COPY build/__pythonVersions.sh /tmp
COPY --from=py27-build-base /opt /opt
COPY --from=py36-build-base /opt /opt
COPY --from=py37-build-base /opt /opt
COPY --from=py38-build-base /opt /opt
RUN . /tmp/__pythonVersions.sh && set -ex \
 && [ -d "/opt/python/$PYTHON27_VERSION" ] && echo /opt/python/$PYTHON27_VERSION/lib >> /etc/ld.so.conf.d/python.conf \
 && [ -d "/opt/python/$PYTHON36_VERSION" ] && echo /opt/python/$PYTHON36_VERSION/lib >> /etc/ld.so.conf.d/python.conf \
 && [ -d "/opt/python/$PYTHON37_VERSION" ] && echo /opt/python/$PYTHON37_VERSION/lib >> /etc/ld.so.conf.d/python.conf \
 && [ -d "/opt/python/$PYTHON38_VERSION" ] && echo /opt/python/$PYTHON38_VERSION/lib >> /etc/ld.so.conf.d/python.conf \
 && ldconfig
# The link from PYTHON38_VERSION to 3.8.0 exists because "3.8.0b1" isn't a valid SemVer string.
RUN . /tmp/__pythonVersions.sh && set -ex \
 && ln -s $PYTHON27_VERSION /opt/python/2.7 \
 && ln -s 2.7 /opt/python/2 \
 && ln -s $PYTHON36_VERSION /opt/python/3.6 \
 && ln -s $PYTHON37_VERSION /opt/python/latest \
 && ln -s $PYTHON37_VERSION /opt/python/3.7 \
 && ln -s $PYTHON38_VERSION /opt/python/3.8.0 \
 && ln -s $PYTHON38_VERSION /opt/python/3.8 \
 && ln -s 3.7 /opt/python/3
RUN set -ex \
 && cd /usr/local/bin \
 && cp -sn /opt/python/2/bin/* . \
 && cp -sn /opt/python/3/bin/* . \
 # Make sure the alias 'python' always refers to Python 2 by default
 && ln -sf /opt/python/2/bin/python python

# This stage is used only when building locally
FROM dotnet-install AS buildscriptbuilder
COPY src/BuildScriptGenerator /usr/oryx/src/BuildScriptGenerator
COPY src/BuildScriptGeneratorCli /usr/oryx/src/BuildScriptGeneratorCli
COPY src/Common /usr/oryx/src/Common
COPY build/FinalPublicKey.snk usr/oryx/build/
COPY src/CommonFiles /usr/oryx/src/CommonFiles
# This statement copies signed oryx binaries from during agent build.
# For local/dev contents of blank/empty directory named binaries are getting copied
COPY binaries /opt/buildscriptgen/
WORKDIR /usr/oryx/src
ARG GIT_COMMIT=unspecified
ARG AGENTBUILD=${AGENTBUILD}
ARG BUILD_NUMBER=unspecified
ENV GIT_COMMIT=${GIT_COMMIT}
ENV BUILD_NUMBER=${BUILD_NUMBER}
COPY images/build/benv.sh /usr/local/bin/benv
RUN chmod +x /usr/local/bin/benv
RUN if [ -z "$AGENTBUILD" ]; then \
        dotnet publish -r linux-x64 -o /opt/buildscriptgen/ -c Release BuildScriptGeneratorCli/BuildScriptGeneratorCli.csproj; \
    fi
RUN chmod a+x /opt/buildscriptgen/GenerateBuildScript

###
# PHP intermediate stages
# Docker doesn't support variables in `COPY --from`, so we're using intermediate stages
###
FROM mcr.microsoft.com/oryx/php-build-base:5.6-${PHP_BUILD_BASE_TAG} AS php56-build-base
FROM mcr.microsoft.com/oryx/php-build-base:7.0-${PHP_BUILD_BASE_TAG} AS php70-build-base
FROM mcr.microsoft.com/oryx/php-build-base:7.2-${PHP_BUILD_BASE_TAG} AS php72-build-base
FROM mcr.microsoft.com/oryx/php-build-base:7.3-${PHP_BUILD_BASE_TAG} AS php73-build-base
###
# End PHP intermediate stages
###

###
# Build run script generators (to be used by the `oryx run-script` command)
###
FROM golang:1.11-stretch as startupScriptGens

# GOPATH is set to "/go" in the base image
WORKDIR /go/src
COPY src/startupscriptgenerator/src .

ARG GIT_COMMIT=unspecified
ARG BUILD_NUMBER=unspecified
ENV GIT_COMMIT=${GIT_COMMIT}
ENV BUILD_NUMBER=${BUILD_NUMBER}

RUN ./build.sh dotnetcore /opt/startupcmdgen/dotnet
RUN ./build.sh node       /opt/startupcmdgen/nodejs
RUN ./build.sh php        /opt/startupcmdgen/php
RUN ./build.sh python     /opt/startupcmdgen/python
###
# End build run script generators
###

FROM main as LtsOnly
WORKDIR /
# Copy Benv
COPY images/build/benv.sh /usr/local/bin/benv
RUN chmod +x /usr/local/bin/benv
RUN mkdir -p /usr/local/share/pip-cache/lib
RUN chmod -R 777 /usr/local/share/pip-cache
# 1. Copy Python sdk
# It's not clear whether these are needed at runtime...
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        tk-dev \
        uuid-dev \
 && rm -rf /var/lib/apt/lists/*
# https://github.com/docker-library/python/issues/147
ENV PYTHONIOENCODING UTF-8
COPY build/__pythonVersions.sh /tmp
COPY --from=py37-build-base /opt /opt
RUN . /tmp/__pythonVersions.sh && set -ex \
 && [ -d "/opt/python/$PYTHON37_VERSION" ] && echo /opt/python/$PYTHON37_VERSION/lib >> /etc/ld.so.conf.d/python.conf \
 && ldconfig
RUN . /tmp/__pythonVersions.sh && set -ex \
 && ln -s $PYTHON37_VERSION /opt/python/latest \
 && ln -s $PYTHON37_VERSION /opt/python/3.7 \
 && ln -s 3.7 /opt/python/3
RUN set -ex \
 && cd /usr/local/bin \
 && cp -sn /opt/python/3/bin/* .
# 2. Copy dotnetcore sdk
ENV NUGET_XMLDOC_MODE=skip \
	DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
	NUGET_PACKAGES=/var/nuget
COPY --from=dotnet-install /opt/dotnet/sdks/2.1.701 /opt/dotnet/sdks/2.1.701
COPY --from=dotnet-install /var/nuget /var/nuget
COPY --from=dotnet-install /usr/local/bin /usr/local/bin
# Grant read-write permissions to the nuget folder so that dotnet restore
# can write into it.
RUN chmod a+rw /var/nuget

FROM python AS final
WORKDIR /

COPY images/build/benv.sh /usr/local/bin/benv
RUN chmod +x /usr/local/bin/benv
RUN mkdir -p /usr/local/share/pip-cache/lib
RUN chmod -R 777 /usr/local/share/pip-cache

# Copy .NET Core related content
ENV NUGET_XMLDOC_MODE=skip \
	DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
	NUGET_PACKAGES=/var/nuget
COPY --from=dotnet-install /opt/dotnet /opt/dotnet
COPY --from=dotnet-install /var/nuget /var/nuget
COPY --from=dotnet-install /usr/local/bin /usr/local/bin
# Grant read-write permissions to the nuget folder so that dotnet restore
# can write into it.
RUN chmod a+rw /var/nuget

# Copy NodeJs, NPM and Yarn related content
COPY --from=node-install /opt /opt
COPY --from=node-install /links/ /usr/local/bin
COPY --from=mcr.microsoft.com/oryx/build-yarn-cache:20190802.1 /usr/local/share/yarn-cache /usr/local/share/yarn-cache

# Copy PHP versions
COPY images/build/php/prereqs/installPrereqs.sh /tmp/php/installPrereqs.sh
RUN . /tmp/php/installPrereqs.sh

COPY --from=php56-build-base /opt /opt
COPY --from=php70-build-base /opt /opt
COPY --from=php72-build-base /opt /opt
COPY --from=php73-build-base /opt /opt

RUN ln -s /opt/php/5.6 /opt/php/5 \
 && ln -s /opt/php/7.3 /opt/php/7 \
 && ln -s /opt/php/7 /opt/php/lts \
 && ln -s /opt/php/lts/bin/php /usr/local/bin/php

# Build script generator content. Docker doesn't support variables in --from
# so we are building an extra stage to copy binaries from correct build stage
COPY --from=buildscriptbuilder /opt/buildscriptgen/ /opt/buildscriptgen/
RUN ln -s /opt/buildscriptgen/GenerateBuildScript /usr/local/bin/oryx

# Oryx depends on the run script generators for most of its
# `IProgrammingPlatform.GenerateBashRunScript()` implementations
COPY --from=startupScriptGens /opt/startupcmdgen/ /opt/startupcmdgen/

# Bake Application Insights key from pipeline variable into final image
ARG AI_KEY
ENV ORYX_AI_INSTRUMENTATION_KEY=${AI_KEY}

ARG GIT_COMMIT=unspecified
ARG BUILD_NUMBER=unspecified
LABEL com.microsoft.oryx.git-commit=${GIT_COMMIT}
LABEL com.microsoft.oryx.build-number=${BUILD_NUMBER}

ENTRYPOINT [ "benv" ]
