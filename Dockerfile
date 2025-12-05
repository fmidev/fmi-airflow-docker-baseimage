FROM apache/airflow:3.1.3

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev gdal-bin libgdal-dev libhdf5-dev hdf5-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    apache-airflow-providers-common-io \
    apache-airflow-providers-amazon \
    apache-airflow-providers-cncf-kubernetes \
    apache-airflow-providers-google \
    apache-airflow-providers-http \
    apache-airflow-providers-snowflake \
    apache-airflow[statsd] \
    apache-airflow[celery] \
    numpy==1.26.4 \
    pandas==2.1.4 \
    scikit-learn==1.3.2 \ 
    scipy==1.12.0 \
    dask[dataframe,distributed]==2025.5.1 \
  && pip check
