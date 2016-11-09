# -*- coding: utf-8 -*-
# vim: ft=sls
#

{% from "etcd/map.jinja" import etcd with context %}

#
# Make sure etcd service is running
#

etcd-service:
  service.running:
    - name: {{ etcd.service-name }}
    - enable: True
