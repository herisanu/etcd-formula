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
        #!/bin/bash

        if [[ ! -x /usr/bin/curl || ! -x /usr/bin/tar || ! -x /usr/bin/gpg ]]; then
          echo "Please install curl, tar and gpg."
          exit 1
        fi

        GITHUB_URL="{{ etcd.lookup.install_base_url }}"
        ETCD_VERSION="{{ etcd.version }}"
        DEST_DIR="{{ etcd.binary_directory }}"
        ETCD_USER="{{ etcd.lookup.user }}"
        ETCD_GROUP="{{ etcd.lookup.group }}"

        if [[ ! $ETCD_VERSION =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
          echo "We're not in a jinja context. Using defaults."
          GITHUB_URL="http://github.com/coreos/etcd/releases/download"
          ETCD_VERSION="3.0.14"
          DEST_DIR="/opt/etcd"
          ETCD_USER="etcd"
          ETCD_GROUP="etcd"
        fi

        echo "Checking if ${DEST_DIR}/etcd-v${ETCD_VERSION}-linux-amd64 exists ..."
        if [[ -d ${DEST_DIR}/etcd-v${ETCD_VERSION}-linux-amd64 ]]; then
          echo "ETCD version ${ETCD_VERSION} is already installed."
          exit 1
        fi

        DOWNLOAD_URL="${GITHUB_URL}/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
        DOWNLOAD_URL_ASC="${DOWNLOAD_URL}.asc"
        PGP_PUBKEY_URL="https://coreos.com/dist/pubkeys/app-signing-pubkey.gpg"
        TMPDIR=`mktemp --directory`

        echo "Downloading and installing etcd ${ETCD_VERSION}"
        echo "from ${DOWNLOAD_URL} .."

        curl -L https://coreos.com/dist/pubkeys/app-signing-pubkey.gpg -o ${TMPDIR}/app-signing-pubkey.gpg
        gpg --import --keyid-format LONG ${TMPDIR}/app-signing-pubkey.gpg

        curl -L "${DOWNLOAD_URL}" -o "${TMPDIR}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
        curl -L "${DOWNLOAD_URL_ASC}" -o "${TMPDIR}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz.asc"

        cd ${TMPDIR}
        gpg --verify etcd-v${ETCD_VERSION}-linux-amd64.tar.gz.asc

        RET="$?"
        if [[ ${RET} -ne 0 ]]; then
          echo "GPG Verification failed. Please check ${TMPDIR}."
          exit 1
        fi

        echo "Extracting ..."
        tar -xzf "${TMPDIR}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz" -C "${DEST_DIR}"
        chown -R ${ETCD_USER}:${ETCD_GROUP} ${DEST_DIR}

        echo "Done."
        if [[ ! -z ${TMPDIR} ]]; then
          rm -Rf ${TMPDIR}
        fi
    - unless:
      - "test -d {{ etcd.binary_directory }}/etcd-v{{ etcd.version }}-linux-amd64"

etcd-alternatives-etcd:
  alternatives.install:
    - name: etcd
    - link: '/usr/bin/etcd'
    - path: '{{ etcd.binary_directory }}/etcd-v{{ etcd.version }}-linux-amd64/etcd'
    - priority: 30
    - onlyif:
      - test -f {{ etcd.binary_directory }}/etcd-v{{ etcd.version }}-linux-amd64/etcd
      - test ! -f /usr/bin/etcdctl

etcd-alternatives-etcdctl:
  alternatives.install:
    - name: etcdctl
    - link: '/usr/bin/etcdctl'
    - path: '{{ etcd.binary_directory }}/etcd-v{{ etcd.version }}-linux-amd64/etcdctl'
    - priority: 30
    - onlyif:
      - test -f {{ etcd.binary_directory }}/etcd-v{{ etcd.version }}-linux-amd64/etcdctl
      - test ! -f /usr/bin/etcdctl
