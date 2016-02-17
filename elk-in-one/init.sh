#!/bin/bash

set -e

if [ "$1" = 'init' ]; then
  #Start services
  systemctl daemon-reload
  systemctl enable iptables
  systemctl enable nginx
  chkconfig logstash on
  systemctl enable elasticsearch
  chkconfig kibana on
  systemctl enable filebeat packetbeat topbeat

  # Jelastic specific instructions
  sed -i "/Extensions for a typical CA/a subjectAltName = IP: EL_SERVER_IP" /etc/pki/tls/openssl.cnf
  openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:4096 -keyout /etc/pki/tls/private/logstash-forwarder.key -out /etc/pki/tls/certs/logstash-forwarder.crt

  systemctl restart iptables
  systemctl restart nginx
  systemctl restart elasticsearch
  sleep 20
  /etc/init.d/logstash restart
  sleep 20
  /etc/init.d/kibana restart

  #Add templates
  cd /tmp; ./load.sh
  $CURL -XPUT "http://${EL_SERVER_IP}:9200/_template/filebeat?pretty" -d@/tmp/filebeat.template.json 
  $CURL -XPUT "http://${EL_SERVER_IP}:9200/_template/topbeat?pretty" -d@/tmp/topbeat.template.json 
  $CURL -XPUT "http://${EL_SERVER_IP}:9200/_template/packetbeat?pretty" -d@/tmp/packetbeat.template.json 

  systemctl restart filebeat packetbeat topbeat
fi

exec "$@"

