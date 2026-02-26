PASSWORD='Ngpqy8Bfk123'


def register_prev(selenium, device_user, ui_mode):
    register_next(selenium, 'prev-' + device_user, ui_mode)


def register_next(selenium, device_user, ui_mode):
    selenium.find_by_xpath("//a[contains(.,'Create account')]").click()
    selenium.find_by_id("register-start_form_input_email").send_keys('{}-{}@example.com'.format(device_user, ui_mode))
    selenium.find_by_id("register-start_form_input_name").send_keys("Test User")
    selenium.find_by_xpath("//button[@type='submit']").click()
    selenium.find_by_id("input-password-form_new-password").send_keys(PASSWORD)
    selenium.find_by_id("input-password-form_new-password-confirm").send_keys(PASSWORD)
#    selenium.find_by_id("acceptPolicies").click()
    selenium.screenshot('register-credentials')
    selenium.find_by_xpath("//button[@type='submit']").click()
    selenium.screenshot('register')


def login(selenium):
    selenium.find_by_xpath("//span[contains(.,'Continue')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('login-credentials')
    selenium.find_by_xpath("//span[contains(.,'Log in')]").click()
    selenium.find_by_xpath("//h3[contains(text(), 'All vaults')]")

def unlock(selenium):
    selenium.find_by_xpath("//span[contains(.,'Unlock')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('unlock-credentials')
    selenium.find_by_xpath("//span[contains(.,'Unlock')]").click()
    selenium.find_by_xpath("//h3[contains(text(), 'All vaults')]")


