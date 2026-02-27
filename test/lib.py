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

def login_stable(selenium, device_user, ui_mode):
    selenium.find_by_xpath("//input[@type='email']").send_keys('{}-{}@example.com'.format(device_user, ui_mode))
    selenium.find_by_xpath("//span[contains(.,'Continue')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('login-stable-credentials')
    selenium.find_by_xpath("//button[contains(.,'Log in with master password')]").click()
    selenium.find_by_xpath("//h1[contains(.,'All vaults')] | //h3[contains(.,'All vaults')]")


def login_upgrade(selenium, device_user, ui_mode):
    selenium.find_by_xpath("//input[@type='email']").send_keys('{}-{}@example.com'.format(device_user, ui_mode))
    selenium.find_by_xpath("//span[contains(.,'Continue')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('login-upgrade-credentials')
    selenium.find_by_xpath("//button[contains(.,'Log in with master password')]").click()
    selenium.find_by_xpath("//*[contains(text(), 'Add it later')]").click()
    selenium.find_by_xpath("//*[contains(text(), 'Skip to web app')]").click()
    selenium.find_by_xpath("//h1[contains(.,'All vaults')]")


def create_item(selenium, name):
    selenium.screenshot('create-item-before-{}'.format(name))
    selenium.find_by_xpath("//button[@id='newItemDropdown']").click()
    selenium.screenshot('create-item-dropdown-{}'.format(name))
    selenium.find_by_xpath("//bit-menu-item[contains(.,'Login')] | //button[@role='menuitem'][contains(.,'Login')]").click()
    selenium.screenshot('create-item-form-{}'.format(name))
    selenium.find_by_xpath("//input[@formcontrolname='name']").send_keys(name)
    selenium.screenshot('create-item-name-filled-{}'.format(name))
    selenium.find_by_xpath("//button[contains(.,'Save')]").click()
    selenium.screenshot('create-item-saved-{}'.format(name))


def has_item(selenium, name):
    selenium.screenshot('has-item-before-{}'.format(name))
    selenium.find_by_xpath("//td[contains(.,'" + name + "')] | //app-vault-items-list//*[contains(.,'" + name + "')] | //cdk-virtual-scroll-viewport//*[contains(.,'" + name + "')]")
    selenium.screenshot('has-item-found-{}'.format(name))


def unlock(selenium):
    selenium.find_by_xpath("//span[contains(.,'Unlock')]").click()
    selenium.find_by_xpath("//input[@type='password']").send_keys(PASSWORD)
    selenium.screenshot('unlock-credentials')
    selenium.find_by_xpath("//span[contains(.,'Unlock')]").click()
    selenium.find_by_xpath("//h3[contains(text(), 'All vaults')]")


