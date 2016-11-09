# -*- coding: utf-8 -*-
# vim: ft=sls
#

{% from "etcd/map.jinja" import etcd with context %}

#
# Configure data and binary directories
# Re-generate service configuration files for systemd and/or upstart
#

etcd-config:
  file.managed:
    - name: {{ etcd.service-config }}
    - source:
    - user: {{ etcd.lookup.user }}
    - group: {{ etcd.lookup.group }}
    - template: jinja

etcd-serivce-file:
  file.managed:
    - name: {{ etcd.service-file }}
    - source: {{ etcd.service-file }}
    - user: root
    - group: root
    - mode: '0640'
    - watch_in:
        service: etcd-service
