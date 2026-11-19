FROM apache/airflow:3.4.0-python3.12 AS base
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
# Its Python wrapper scripts are skipped here; the GDAL Python package installed at
# the end of this file provides them (gdal_calc.py, gdal_merge.py, ...).
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

# rasterio 1.5 requires numpy 2; 1.4.4 works with the numpy 1.26 pin.
# Its wheels bundle their own GDAL, independent of the system libgdal.
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
    rasterio==1.4.4 \
  && pip check


# GDAL Python bindings (osgeo) and scripts, built against the system libgdal.
# PyPI has only a source distribution, and the image ships no compiler, so build
# the wheel in a throwaway stage and copy just the wheel into the final image.
FROM base AS gdal-python

USER root

# The Python headers must be the exact version of the image's held Python
# packages, otherwise apt would try to upgrade them.
RUN apt-get update \
  && apt-get install -y --no-install-recommends gcc g++ \
  && py_minor=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])') \
  && py_include=$(python3 -c 'import sysconfig; print(sysconfig.get_paths()["include"])') \
  && if [ ! -f "$py_include/Python.h" ]; then \
       apt-get install -y --no-install-recommends \
         "libpython-${py_minor}-dev=$(dpkg-query -W -f='${Version}' "libpython-${py_minor}")"; \
     fi

USER airflow

# The bindings must match the libgdal version exactly. PIP_USER=false: the image
# sets PIP_USER=true, which breaks pip's isolated build environment.
RUN PIP_USER=false pip wheel --no-cache-dir --no-deps --wheel-dir /tmp/wheels \
      "GDAL==$(gdal-config --version)"


FROM base

COPY --from=gdal-python --chown=airflow:0 /tmp/wheels /tmp/wheels

RUN pip install --no-cache-dir --no-deps /tmp/wheels/*.whl \
  && rm -rf /tmp/wheels \
  && pip check \
  && python -c "from osgeo import gdal, gdal_array; print('GDAL', gdal.__version__)" \
  && gdal_calc.py --help > /dev/null \
  && python -c "import rasterio; print('rasterio', rasterio.__version__)"
