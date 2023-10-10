FROM apache/airflow:2.7.1
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev gdal-bin libgdal-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow
RUN pip install 'astronomer-providers[amazon]==1.9.0' \
    	    'astronomer-providers[cncf.kubernetes]==1.9.0' \
	    'astronomer-providers[google]==1.9.0' \
	    'astronomer-providers[http]==1.9.0' \
	    'astronomer-providers[snowflake]==1.9.0' \
	    'apache-airflow[statsd]'