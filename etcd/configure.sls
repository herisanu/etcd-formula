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

# etcd > 3.x.x is not compatible with TLSv1, which is used py the python-etcd
# module. We need to patch it to disable TLSv1. This is the change introduced in
# commit: https://github.com/jplana/python-etcd/commit/0d0145f5e835aa032c97a0a5e09c4c68b7a03f66
{% if etcd.patch_python_etcd == True %}
{{ etcd.python_client_lib_path }}:
  file.patch:
    - source: salt://files/etcd_client_ssl_tlsv12.patch
    - hash: md5=09d0a08a56477209afa82dbef1dd596f
{% endif %}
