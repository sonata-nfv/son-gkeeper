#!/bin/bash
docker run -i \

-e RACK_ENV=integration \
-e CATALOGUES_URL=http://son-catalogue-repository:4011/catalogues/api/v2 \
-v "$(pwd)/spec/reports/son-gtkpkg:/app/spec/reports" \
registry.sonata-nfv.eu:5000/son-gtkpkg bundle exec rake ci:all

