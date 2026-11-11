FROM apache/airflow:3.4.0-python3.12
#FROM apache/airflow:3.2.0-python3.12
#FROM apache/airflow:3.1.3-python3.12
#FROM apache/airflow:2.11.0
#FROM apache/airflow:3.1.3
#

USER root

# gdal-bin cannot be apt-installed on the Airflow >= 3.4.0 (Debian 13 hardened) image:
# it depends on Debian's python3/python3-gdal, which conflict with the image's held
# python-3.12 packages. The GDAL command line tools themselves only need libgdal
# (pulled in by libgdal-dev), so download the package and copy its compiled binaries
# (gdalinfo, gdal_translate, gdalwarp, ogr2ogr, ...) without registering it in dpkg.
# The Python wrapper scripts (gdal_calc.py, gdal_merge.py, ...) are skipped as they
# need the osgeo bindings for Debian's python3.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libpq-dev libgeos-dev libgdal-dev libhdf5-dev hdf5-tools \
  && mkdir /tmp/gdal-bin && cd /tmp/gdal-bin \
  && apt-get download gdal-bin \
  && dpkg-deb -x gdal-bin_*.deb . \
  && for f in usr/bin/*; do \
       head -c 2 "$f" | grep -q '^#!' || install -m 0755 "$f" /usr/bin/; \
     done \
  && cd / && rm -rf /tmp/gdal-bin \
  && gdalinfo --version && ogr2ogr --version \
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
    xarray==2024.07.0 \
  && pip check
