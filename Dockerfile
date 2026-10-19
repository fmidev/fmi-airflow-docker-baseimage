# FMI Airflow base image, Airflow 2.x line.
# The official image already includes the providers used here (amazon, celery,
# cncf-kubernetes, common-io, docker, google, http, snowflake) and statsd.
ARG AIRFLOW_VERSION=2.11.2
# Not PYTHON_VERSION: the base image sets ENV PYTHON_VERSION=3.12.x, which
# some builders let override an ARG of the same name.
ARG PYTHON_MINOR=3.12

FROM apache/airflow:${AIRFLOW_VERSION}-python${PYTHON_MINOR}

ARG AIRFLOW_VERSION
ARG PYTHON_MINOR

USER root

# The base image enables the PostgreSQL apt repository (pgdg), which also ships
# newer GDAL, GEOS and PROJ. Take those from Debian (-t bookworm) so that the
# gdal-bin tools used by BashOperator tasks keep their Debian 12 versions.
RUN apt-get update \
  && apt-get install -y --no-install-recommends libpq-dev \
  && apt-get install -y --no-install-recommends -t bookworm \
         libgeos-dev gdal-bin libgdal-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Pinning apache-airflow and using the constraints file keeps pip from
# upgrading Airflow or its dependencies to satisfy the extra packages.
# astronomer-providers is deprecated upstream; kept for the DAGs that still use it.
# rasterio wheels bundle their own GDAL, independent of the system gdal-bin.
RUN pip install --no-cache-dir \
    "apache-airflow==${AIRFLOW_VERSION}" \
    "astronomer-providers[amazon,cncf.kubernetes,google,http,snowflake]==1.18.0" \
    "rasterio==1.4.4" \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_MINOR}.txt" \
  && pip check
