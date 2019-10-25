#!/bin/bash
gcloud functions deploy bq-bridge --runtime go111 --entry-point Handler --trigger-http --project chainlink-marketing-roi