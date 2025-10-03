FROM apache/airflow:3.1.0

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev gdal-bin libgdal-dev libhdf5-dev hdf5-tools \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    'astronomer-providers[amazon]' \
    'astronomer-providers[cncf.kubernetes]' \
    'astronomer-providers[google]' \
    'astronomer-providers[http]' \
    'astronomer-providers[snowflake]' \
    'apache-airflow[statsd]' \
    'apache-airflow[celery]' \
    'numpy==2.3.3' \
    'scipy==1.12.3' \
    'scikit-learn==1.7.2' \
  && pip check
