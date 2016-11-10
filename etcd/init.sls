# -*- coding: utf-8 -*-
# vim: ft=sls
#

{% from "etcd/map.jinja" import dtm with context %}

#
# Install, configure and make sure the etcd service is running
#

include:
  - etcd.install
  - etcd.configure
  - etcd.service
