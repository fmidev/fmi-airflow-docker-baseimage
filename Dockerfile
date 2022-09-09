FROM apache/airflow:2.3.3
RUN pip install 'astronomer-providers[all]'