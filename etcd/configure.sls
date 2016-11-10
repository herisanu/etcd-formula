# -*- coding: utf-8 -*-
# vim: ft=sls
#

{% from "etcd/map.jinja" import etcd with context %}

#
# Configure data and binary directories
# Re-generate service configuration files for systemd and/or upstart
#

{% if etcd.use_systemd == True %}
etcd-systemd-config:
  file.managed:
    - name: '/etc/systemd/system/{{ etcd.lookup.service_name }}.service'
    - source: 'salt://etcd/files/systemd/etcd.service.jinja2'
    - user: root
    - group: root
    - mode: '0750'
    - template: jinja
    - context:
      etcd: {{ etcd }}
    - watch_in:
      - service: etcd-service

etcd-systemctl-reload:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: etcd-systemd-config
{% endif %}

{% if etcd.use_upstart == True %}
etcd-upstart-config:
  file.managed:
    - name: '/etc/init/{{ etcd.lookup.service_name }}.conf'
    - source: 'salt://etcd/files/upstart/etcd.conf.jinja2'
    - user: root
    - group: root
    - mode: '0750'
    - template: jinja
    - context:
      etcd: {{ etcd }}
    - watch_in:
      - service: etcd-service
{% endif %}
