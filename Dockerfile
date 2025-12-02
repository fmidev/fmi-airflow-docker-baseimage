# Use Airflow 3 base image
FROM apache/airflow:3.1.3

USER root

# Install OS-level dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev gdal-bin libgdal-dev libhdf5-dev hdf5-tools \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Install Python dependencies (Airflow extras, providers, and scientific libraries)
RUN pip install --no-cache-dir \
    "astronomer-providers[amazon]==1.19.4" \
    "astronomer-providers[cncf.kubernetes]==1.19.4" \
    "astronomer-providers[google]==1.19.4" \
    "astronomer-providers[http]==1.19.4" \
    "astronomer-providers[snowflake]==1.19.4" \
    "apache-airflow[statsd]" \
    "apache-airflow[celery]" \
    "numpy==1.26.4" \
    "pandas==2.1.4" \
    "scikit-learn==1.3.2" \
  && pip check
