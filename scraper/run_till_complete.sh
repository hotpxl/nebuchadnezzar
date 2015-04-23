#!/bin/bash
cd /home/yutian/js/nebuchadnezzar
RUN=1
while [[ ${RUN} -ne 0 ]]; do
  npm start
  RUN=$?
done

