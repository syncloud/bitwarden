import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import {
  registerUser,
  dismissPostLoginPrompts,
  expectAtVault,
} from '../helpers/vault'

const email = 'smoke@example.com'

test.describe('bitwarden smoke', () => {
  test('register and reach vault', async ({ page }, testInfo) => {
    await page.goto('/')
    await shoot(page, testInfo, 'index')
    await registerUser(page, email)
    await shoot(page, testInfo, 'register-done')
    await dismissPostLoginPrompts(page)
    await expectAtVault(page)
    await shoot(page, testInfo, 'vault')
  })
})
