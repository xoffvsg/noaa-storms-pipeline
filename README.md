# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data, converts it to GeoParquet, and lands it ready for analysis in DuckDB, GeoPandas, or QGIS.

## What it does

`pipeline.sh` takes a year (default: 2024), pulls the raw `details` file from NOAA's public archive, decompresses it, and converts it to a single GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet connection.


The script includes safeguards to make sure no error is caused if the same file is downloaded twice.
First run output:
<img width="1600" alt="Webpage_landing" src="">

Following runs output:
<img width="1600" alt="Webpage_landing" src="">

The GeoParquet file has been verified in QGIS.


## The data

- **Source:** [NOAA Storm Events Database](https://www.ncei.noaa.gov/data/storm-events/)
- **License:** Public domain (US federal data)
- **What's in it:** every recorded storm event in the United States for the given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

```bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
```

To run for a specific year:

```bash
./pipeline.sh 2023
```

## What I learned

Gained more familiarity with the **curl** function.
    Found out the hard way that the order of the flags matters `-o`.
    Some error (<i>schannel: next InitializeSecurityContext failed: Unknown error (0x80092012) - The revocation function was unable to check revocation for the certificate.</i>). This might be caused with my antivirus blocking Windows from verifying that the server's TLS certificate hasn't been revoked, by contacting an OCSP or CRL endpoint (a separate check from the cert itself being valid). If that revocation check can't complete, the SSL-inspection tool is blocking the connection to the revocation server and curl aborts the whole request rather than silently trusting a cert it couldn't fully verify. This was fixed by adding `--ssl-no-revoke`
<cr>
The gunzip and ogr2ogr worked as advertized without troubleshooting required.    

## Stack

- bash
- curl
- GDAL / ogr2ogr
- GeoParquet
