# GDAL Python bindings (osgeo) and scripts (gdal_calc.py, gdal_merge.py, ...).
# PyPI has only a source distribution and the Airflow image has no compiler, so
# build the wheel here and copy only the wheel into the final image. This stage
# uses the plain Debian 13 (trixie) Python image on purpose: installing -dev
# packages into the Airflow image fails, because its Docker Hardened Image
# libraries no longer match the -dev packages in Docker's apt repository.
# Keep the Python minor version in line with the Airflow image below.
FROM python:3.12-trixie AS gdal-python

RUN apt-get update \
  && apt-get install -y --no-install-recommends libgdal-dev \
  && rm -rf /var/lib/apt/lists/*

# The bindings must match the libgdal version, which comes from Debian trixie
# in both this stage and the final image.
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /tmp/wheels \
      "GDAL==$(gdal-config --version)"


FROM apache/airflow:3.4.0-python3.12

USER root

# The Airflow image ranks the PostgreSQL apt repository (PGDG) above everything
# else so that it can take libpq from there. PGDG also ships GDAL, GEOS and PROJ,
# newer than Debian's and not installable on this image, so rank those below
# Debian. Package-specific pins take precedence over the image's "Package: *" pin.
RUN printf '%s\n' \
      'Package: gdal-* libgdal* python3-gdal geos-* libgeos* proj-* libproj* libsfcgal* libcgal*' \
      'Pin: origin "apt.postgresql.org"' \
      'Pin-Priority: 100' \
      > /etc/apt/preferences.d/fmi-gis-from-debian

# Only runtime libraries: -dev packages cannot be installed on this image (see the
# first stage), and without a compiler they would not be useful anyway.
#
# gdal-bin cannot be apt-installed: it depends on Debian's python3/python3-gdal,
# which conflict with the image's held python-3.12 packages. Its compiled tools
# (gdalinfo, gdal_translate, gdalwarp, ogr2ogr, ...) only need libgdal, so download
# the package, install the libgdal it depends on, and copy the binaries without
# registering gdal-bin in dpkg. Its Python wrapper scripts are skipped; the GDAL
# wheel installed at the end provides them.
RUN apt-get update \
  && mkdir /tmp/gdal-bin && cd /tmp/gdal-bin \
  && apt-get download gdal-bin \
  && libgdal=$(dpkg-deb -f gdal-bin_*.deb Depends | grep -o 'libgdal[0-9]\+' | head -n 1) \
  && apt-get install -y --no-install-recommends \
         "$libgdal" libgeos-c1t64 hdf5-tools \
  && dpkg-deb -x gdal-bin_*.deb . \
  && for f in usr/bin/*; do \
       head -c 2 "$f" | grep -q '^#!' || install -m 0755 "$f" /usr/bin/; \
     done \
  && cd / && rm -rf /tmp/gdal-bin \
  && gdalinfo --version && ogr2ogr --version \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

COPY --from=gdal-python --chown=airflow:0 /tmp/wheels /tmp/wheels

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
    /tmp/wheels/*.whl \
  && rm -rf /tmp/wheels \
  && pip check \
  && python -c "from osgeo import gdal, gdal_array; print('GDAL', gdal.__version__)" \
  && gdal_calc.py --help > /dev/null \
  && python -c "import rasterio; print('rasterio', rasterio.__version__)"
