# -*- coding: utf-8 -*-
# vim: ft=yaml

{% from "etcd/map.jinja" import etcd with context -%}

#
# Installs etcd version by downloading the archive from github
# and extracting it to the {{ etcd.binary_directory }} directory.
#
# This will also set alternatives for the etcdctl and daemon binary.
# Depending if it's a systemd or a upstart configuration, this will copy
# the right service definition.
#

{% set etcd_name = "etcd-v" + etcd_settings.install.version + "-linux-amd64" -%}
{% set etcd_archive_name = etcd_name + ".tar.gz" -%}
{% set etcd_package_url = "v" + etcd_settings.install.version + "/" + etcd_archive_name -%}

{% if etcd.manage_users == True %}
etcd-create-user:
  group.present:
    - name: etcd
    - system: True
  user.present:
    - name: etcd
    - gid: etcd
    - home: {{ etcd.binary_directory }}
    - createhome: True
{% endif %}

etcd-directories-dependency:
  file.directory:
    - names:
      - {{ etcd.binary_directory }}
      - {{ etcd.data_directory }}
    - user: {{ etcd.lookup.user }}
    - group: {{ etcd.lookup.group }}
    - mode: '0750'

etcd-install:
  cmd.run:
    - name: |
        echo "Downloading and installing etcd {{ etcd.version }}"
