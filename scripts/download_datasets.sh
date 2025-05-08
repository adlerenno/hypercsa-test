#!/bin/bash

# Download Orkhut
cd ../data || exit
URL="https://snap.stanford.edu/data/bigdata/communities/com-orkut.all.cmty.txt.gz"
FILENAME="com-orkut.all.cmty.txt.gz"
TXT_FILE="com-orkut.all.cmty.txt"
CSV_FILE="com-orkut.txt"
if [ ! -f "$FILENAME" ]; then
    curl -O "$URL"
else
    echo "$FILENAME already exists. Skipping download."
fi

# Unzip the file
if [ -f "$FILENAME" ]; then
    if [ -f "$TXT_FILE" ]; then
        echo "$TXT_FILE exists. Skipping decompression."
    else
        gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
    fi
else
    echo "Error: $FILENAME not found!"
fi
python3 ../scripts/normalize_to_csv.py "$TXT_FILE" "$CSV_FILE"

# Download Friendster
URL="https://snap.stanford.edu/data/bigdata/communities/com-friendster.all.cmty.txt.gz"
FILENAME="com-friendster.all.cmty.txt.gz"
TXT_FILE="com-friendster.all.cmty.txt"
CSV_FILE="com-friendster.txt"
if [ ! -f "$FILENAME" ]; then
    curl -O "$URL"
else
    echo "$FILENAME already exists. Skipping download."
fi

# Unzip the file
if [ -f "$FILENAME" ]; then
    if [ -f "$TXT_FILE" ]; then
        echo "$TXT_FILE exists. Skipping decompression."
    else
        gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
    fi
else
    echo "Error: $FILENAME not found!"
fi
python3 ../scripts/normalize_to_csv.py "$TXT_FILE" "$CSV_FILE"

git clone https://git.cs.uni-paderborn.de/eadler/datasets-hypercsa-test.git
python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-senate-committees.txt senate-committees.txt
python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-stackoverflow-answers.txt stackoverflow-answers.txt
python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-walmart-trips.txt walmart-trips.txt
