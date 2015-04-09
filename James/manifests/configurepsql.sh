#!/bin/bash

# First try to restart the postgresql
service postgresql restart > /dev/null 2>1
status=$?

#if [ ! -d "/var/lib/pgsql/data" ]; then
if [ $status -gt 0 ]; then
echo "initdb required , so inititing it"
service postgresql initdb
service postgresql start
sudo -u postgres psql -c "CREATE ROLE puppetdb with LOGIN PASSWORD 'puppetdb'"
sudo -u postgres createdb -E UTF8 -O puppetdb puppetdb

echo "
local  all         postgres                          ident
local  all         all                               md5
host   all         all         127.0.0.1/32          md5
host   all         all         ::1/128               md5
host   puppetdb    puppetdb    10.0.2.0/24           md5
host   puppetdb    puppetdb    172.28.128.0/24        md5
" > /var/lib/pgsql/data/pg_hba.conf
fi 

echo "postgresql restarted successfullly"

/bin/true

exit
