#!/usr/bin/env bash

# docker run -it -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_PASSWORD=password postgres
docker run --rm --name postgres -v .:/data -e POSTGRES_PASSWORD=password -d postgres

# you can run the test SQL from /data in another shell, e.g.
# docker exec -it -e PGUSER=postgres postgres bash
