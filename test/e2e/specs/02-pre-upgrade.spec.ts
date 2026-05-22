import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import {
  registerUser,
  dismissPostLoginPrompts,
  expectAtVault,
  createItem,
  expectItem,
} from '../helpers/vault'

const email = 'upgrade@example.com'
const preItem = 'pre-upgrade-secret'

test.describe('bitwarden pre-upgrade', () => {
  test('register and seed pre-upgrade vault item', async ({ page }, testInfo) => {
    await registerUser(page, email)
    await shoot(page, testInfo, 'register-done')
    await dismissPostLoginPrompts(page)
    await expectAtVault(page)
    await createItem(page, preItem)
    await shoot(page, testInfo, 'pre-upgrade-created')
    await expectItem(page, preItem)
  })
})
