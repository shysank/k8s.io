#!/usr/bin/env bash
set -euo pipefail

curl -o /tmp/autnums.html -L https://bgp.potaroo.net/cidr/autnums.html
python3 /app/asn-vendor-autnums-extractor.py /tmp/autnums.html /tmp/potaroo_data.csv

# Strip data to only return ASN numbers
< /tmp/potaroo_data.csv cut -d ',' -f1 | sed 's/"//' | sed 's/"//' | sed '/^$/d' | cut -d 'S' -f2 > /tmp/potaroo_asn.txt

# remove the '^AS' from each line
< /tmp/potaroo_data.csv tail -n +2 | sed 's,^AS,,g' > /tmp/potaroo_asn_companyname.csv

## GET PYASN section
## using https://github.com/ii/org/blob/main/research/asn-data-pipeline/etl_asn_vendor_table.org

## pyasn installs its utils in ~/.local/bin/*
## Add pyasn utils to path (dockerfile?)
## full list of RIB files on ftp://archive.routeviews.org//bgpdata/2021.05/RIBS/
cd /tmp
if [ ! -f "rib.latest.bz2" ]; then
    pyasn_util_download.py --latest
    mv rib.*.*.bz2 rib.latest.bz2
fi
## Convert rib file to .dat we can process
if [ ! -f "ipasn_latest.dat" ]; then
    pyasn_util_convert.py --single rib.latest.bz2 ipasn_latest.dat
fi
## Run the py script we are including in the docker image
python3 /app/ip-from-pyasn.py /tmp/potaroo_asn.txt ipasn_latest.dat /tmp/pyAsnOutput.csv
## This will output pyasnOutput.csv
