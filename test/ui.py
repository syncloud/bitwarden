from os.path import dirname, join
from subprocess import check_output

import pytest
from syncloudlib.integration.hosts import add_host_alias
from test import lib

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'



@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_index(selenium):
    selenium.open_app()
    selenium.screenshot('index')


def test_register(selenium, device_user, ui_mode):
    lib.register_next(selenium, device_user, ui_mode)
    

def test_login(selenium):
    # lib.login(selenium)
    selenium.find_by_xpath("//h3[contains(text(), 'All vaults')]")

    selenium.screenshot('main')

