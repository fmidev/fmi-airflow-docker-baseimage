FROM apache/airflow:2.4.0
RUN pip install 'astronomer-providers[amazon]==1.9.0' \
    	    'astronomer-providers[cncf.kubernetes]==1.9.0' \
	    'astronomer-providers[google]==1.9.0' \
	    'astronomer-providers[http]==1.9.0' \
	    'astronomer-providers[snowflake]==1.9.0'

