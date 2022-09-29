FROM apache/airflow:2.4.0
RUN pip install 'astronomer-providers[all]==1.9.0'