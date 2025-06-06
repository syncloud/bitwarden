from os.path import dirname, join
from subprocess import check_output

import pytest
from syncloudlib.integration.hosts import add_host_alias

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'
PASSWORD='Ngpqy8Bfk123'


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
    selenium.find_by_xpath("//a[contains(.,'Create account')]").click()
    selenium.find_by_id("register-form_input_email").send_keys('{}-{}@example.com'.format(device_user, ui_mode))
    selenium.find_by_id("register-form_input_name").send_keys("Test User")
    selenium.find_by_id("register-form_input_master-password").send_keys(PASSWORD)
    selenium.find_by_id("register-form_input_confirm-master-password").send_keys(PASSWORD)
#    selenium.find_by_id("acceptPolicies").click()
    selenium.screenshot('register-credentials')
    selenium.find_by_xpath("//button[@type='submit']").click()
    selenium.screenshot('register')


def test_login(selenium):
    selenium.find_by_xpath("//span[contains(.,'Continue')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('login-credentials')
    selenium.find_by_xpath("//span[contains(.,'Log in')]").click()
    selenium.find_by_xpath("//h3[contains(text(), 'All vaults')]")
    selenium.screenshot('main')

