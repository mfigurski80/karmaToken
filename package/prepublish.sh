#!/bin/bash

echo "Prepublish running"

pwd

cp ../build/contracts/* ./contracts
python3 ../scripts/buildAddressesJson.py ../public/addresses.txt > ./addresses.json

