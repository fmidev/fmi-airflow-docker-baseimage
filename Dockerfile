FROM apache/airflow:2.11.0
#FROM apache/airflow:2.10.5
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev gdal-bin libgdal-dev libhdf5-dev hdf5-tools\
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow
RUN pip install 'astronomer-providers[amazon]==1.18.0' \
    	    'astronomer-providers[cncf.kubernetes]==1.18.0' \
	    'astronomer-providers[google]==1.18.0' \
	    'astronomer-providers[http]==1.18.0' \
	    'astronomer-providers[snowflake]==1.18.0' \
	    'apache-airflow[statsd]' \
	    'apache-airflow[celery]'