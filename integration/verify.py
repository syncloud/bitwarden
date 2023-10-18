import os
import pytest
import requests
from os.path import dirname, join
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, data_dir, platform_data_dir, app_dir, artifact_dir, snap_data_dir):
    def module_teardown():
        platform_log_dir = join(artifact_dir, 'platform_log')
        os.mkdir(platform_log_dir)
        device.scp_from_device('{0}/log/*'.format(platform_data_dir), platform_log_dir)

        device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/log/messages {0}/messages.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/app.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/data.ls.log'.format(data_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/web/ > {1}/web.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/log/ > {1}/log.ls.log'.format(data_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/snap.data.ls.log'.format(snap_data_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/data > {1}/snap.data.data.ls.log'.format(snap_data_dir, TMP_DIR), throw=False)
      
        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('{0}/log/*.log'.format(data_dir), app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        device.scp_from_device('{0}/config/*'.format(snap_data_dir), artifact_dir, throw=False)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, app, domain, device_host):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100, throw=True)


def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_session, device_password, domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_installer(device_session, domain)


def test_index(app_domain):
    response = requests.get('https://{0}'.format(app_domain), verify=False)
    assert response.status_code == 200, response.text


def test_storage_change_event(device):
    device.run_ssh('snap run bitwarden.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)
