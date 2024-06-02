#!/usr/bin/bash

psql < insert-set1.sql
psql < query.sql
psql < insert-set2.sql
psql < query.sql