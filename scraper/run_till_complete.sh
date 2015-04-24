#!/bin/bash
cd /home/yutian/js/nebuchadnezzar/scraper
RUN=1
while [[ ${RUN} -ne 0 ]]; do
  DEBUG=* coffee main.coffee &> log
  RUN=$?
done

