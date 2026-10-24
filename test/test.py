import json
import os
import pytest
import requests
from os.path import dirname, join
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer
from syncloudlib.http import wait_for_rest

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'
MASTER_PASSWORD_HASH = 'aGFzaA=='
ENCRYPTED = '2.AAAA|BBBB|CCCC'


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
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_session, device_password, domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_installer(device_session, domain)


def test_index(app_domain):
    wait_for_rest(requests.session(), 'https://{0}'.format(app_domain), 200, 100)


def test_notifications_hub_proxied(app_domain):
    response = requests.get('https://{0}/notifications/hub'.format(app_domain), verify=False)
    assert response.status_code != 502, response.text


def test_storage_change_event(device):
    device.run_ssh('snap run bitwarden.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_backup(device, app_domain, artifact_dir):
    wait_for_rest(requests.session(), 'https://{0}'.format(app_domain), 200, 100)
    register(app_domain, 'before@example.com')
    assert login(app_domain, 'before@example.com') == 200
    out = device.run_ssh('snap run platform.cli backup create bitwarden', throw=False)
    response = device.run_ssh('snap run platform.cli backup list')
    open(join(artifact_dir, 'cli.backup.list.json'), 'w').write(response)
    backups = [b for b in json.loads(response) if b['app'] == 'bitwarden']
    assert backups, 'backup create failed:\n{0}'.format(out)
    backup = backups[-1]
    entries = device.run_ssh('tar tzf {0}/{1}'.format(backup['path'], backup['file'])).split()
    open(join(artifact_dir, 'backup.tar.list.log'), 'w').write('\n'.join(entries))
    for entry in ['./current/db.sqlite3', './current/rsa_key.pem', './current/config/nginx.conf', './common']:
        assert entry in entries, 'backup {0} has no {1}:\n{2}'.format(backup['file'], entry, out)


def test_restore(device, app_domain):
    backup = [b for b in json.loads(device.run_ssh('snap run platform.cli backup list')) if b['app'] == 'bitwarden'][-1]
    wait_for_rest(requests.session(), 'https://{0}'.format(app_domain), 200, 100)
    register(app_domain, 'after@example.com')
    assert login(app_domain, 'after@example.com') == 200
    device.run_ssh('snap run platform.cli backup restore {0}'.format(backup['file']))
    wait_for_rest(requests.session(), 'https://{0}'.format(app_domain), 200, 100)
    assert login(app_domain, 'before@example.com') == 200
    assert login(app_domain, 'after@example.com') == 400


def register(app_domain, email):
    response = requests.post('https://{0}/identity/accounts/register'.format(app_domain), verify=False, json={
        'email': email,
        'name': email,
        'masterPasswordHash': MASTER_PASSWORD_HASH,
        'masterPasswordHint': '',
        'key': ENCRYPTED,
        'kdf': 0,
        'kdfIterations': 600000,
        'keys': {'publicKey': 'public', 'encryptedPrivateKey': ENCRYPTED},
    })
    assert response.status_code == 200, response.text


def login(app_domain, email):
    response = requests.post('https://{0}/identity/connect/token'.format(app_domain), verify=False, data={
        'grant_type': 'password',
        'username': email,
        'password': MASTER_PASSWORD_HASH,
        'scope': 'api offline_access',
        'client_id': 'web',
        'deviceType': '10',
        'deviceIdentifier': '3a8d8e3f-9a1c-4a8e-9c1e-0d0b1d2c3e4f',
        'deviceName': 'test',
    })
    return response.status_code
