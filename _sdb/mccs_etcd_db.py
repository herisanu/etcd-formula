# -*- coding: utf-8 -*-
'''
MCCS etcd Database Module

:maintainer:    SaltStack
:maturity:      New
:depends:       python-etcd
:platform:      all

.. versionadded:: 2015.5.0

This module allows access to the etcd database using an ``sdb://`` URI. This
package is located at ``https://pypi.python.org/pypi/python-etcd``.

Like all sdb modules, the etcd module requires a configuration profile to
be configured in either the minion or master configuration file. This profile
requires very little. In the example:

.. code-block:: yaml

    myetcd:
      driver: mccs_etcd
      etcd.host: 127.0.0.1
      etcd.port: 2379

The ``driver`` refers to the etcd module, ``etcd.host`` refers to the host that
is hosting the etcd database and ``etcd.port`` refers to the port on that host.

.. code-block:: yaml

    password: sdb://myetcd/mypassword

'''

# import python libs
from __future__ import absolute_import
import logging

try:
    import etcd
    import salt.utils.etcd_util
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)

__func_alias__ = {
    'set_': 'set'
}

__virtualname__ = 'mccs_etcd'


def __virtual__():
    '''
    Only load the module if keyring is installed
    '''
    if HAS_LIBS:
        return __virtualname__
    return False


def set_(key, value, service=None, profile=None):  # pylint: disable=W0613
    '''
    Set a key/value pair in the etcd service.
    If the last character of a key is :, then this will create an
    empty directory.
    '''
    if key is None or len(key) == 0:
        return None

    is_directory = (key[-1] == ':')

    client = _get_conn(profile)
    key_ = key.replace(':','/')

    client.set(key_, value, directory=is_directory)

    return get(key, service, profile)


def get(key, service=None, profile=None):  # pylint: disable=W0613
    '''
    Get a value from the etcd service
    '''
    if key is None:
        return None

    client = _get_conn(profile)
    key = key.replace(':','/')
    leaf_key_name = key.split('/')[-1]

    result = {}
    try:
        result = client.tree(key)
    except etcd.EtcdKeyNotFound:
        # etcd already logged that the key wasn't found, no need to do
        # anything here but return
        return None
    except etcd.EtcdConnectionFailed:
        log.error("etcd: failed to perform 'get' operation on key {0} due to connection error".format(key))
        return None
    except ValueError:
        return None


    if result is not None and isinstance(result, dict) and len(result) == 1 and _dict_depth(result) == 1 and leaf_key_name in result:
        result = result[leaf_key_name]

    return result

def _get_conn(profile):
    '''
    Get a connection
    '''
    return salt.utils.etcd_util.get_conn(profile)

def _dict_depth(d, depth=0):
    if not isinstance(d, dict) or not d:
        return depth
    return max(_dict_depth(v, depth+1) for k, v in d.iteritems())
