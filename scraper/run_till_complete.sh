#!/bin/bash
cd /home/yutian/js/nebuchadnezzar/scraper
DEBUG=* coffee main.coffee &> log
RUN=$?
MAIL_SENT=0
while [[ ${RUN} -ne 0 ]]; do
  if [[ ${MAIL_SENT} -eq 0 ]]; then
    ../utils/send-mail.coffee --to "hotpxless@gmail.com" --text "$(tail -n 100 log)"
    MAIL_SENT=1
  fi
  DEBUG=* coffee main.coffee &> log
  RUN=$?
done

