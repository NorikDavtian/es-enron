#!/bin/bash

# DROP DATABASE
cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres -c \
  "DROP DATABASE IF EXISTS enron;"
EOF

# CREATE DATABASE
cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres -c \
  "CREATE DATABASE enron;"
EOF

cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres -c \
  "CREATE EXTENSION btree_gist;"
EOF

# CREATE TABLE
cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres enron -c \
  "CREATE TABLE IF NOT EXISTS emails (
    sender       VARCHAR(255) NOT NULL,
    recipients   TEXT,
    cc           TEXT,
    bcc          TEXT,
    subject      VARCHAR(1024),
    body         TEXT,
    datetime     TIMESTAMP WITH TIME ZONE
  );"
EOF

# CREATE INDEXes
cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres enron -c \
  "CREATE INDEX emails_sender ON emails(sender);"
EOF

cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres enron -c \
  "CREATE INDEX emails_subject ON emails(subject);"
EOF

cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres enron -c \
  "CREATE INDEX emails_body ON emails USING GIST(to_tsvector('english', 'body'));"
EOF

# Transform dataset
# @TODO cleanup the path
echo "# Transform dataset"
node transform_for_mysql_bulk_load.js > ../genus-dashboard-apis/priv/data/emails.csv

# Load dataset
echo "# Load dataset"
cat <<EOF | docker exec genus-dashboard-apis-postgres psql -U postgres enron -c \
    "COPY emails FROM '/var/lib/postgresql/data/emails.csv' DELIMITER ',' CSV HEADER;"
EOF

# Cleanup
#echo "# Cleanup"
#rm /tmp/emails.csv
