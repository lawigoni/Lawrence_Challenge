#!/bin/bash

set -e

# Check that the web server is running and serving the correct content
response=$(curl -s http://${1})
if [[ "$response" != *"<h1>Hello World!</h1>"* ]]; then
  echo "Error: web server not serving the correct content"
  exit 1
fi

# Check that HTTP requests are redirected to HTTPS
response=$(curl -s -I http://${1} | head -n 1 | awk '{print $2}')
if [ "$response" != "301" ]; then
  echo "Error: HTTP requests not redirected to HTTPS"
  exit 1
fi

# Check that the SSL certificate is valid
response=$(curl -s -I https://${1} | head -n 1 | awk '{print $2}')
if [ "$response" != "200" ]; then
  echo "Error: SSL certificate not valid"
  exit 1
fi

echo "All tests passed"
