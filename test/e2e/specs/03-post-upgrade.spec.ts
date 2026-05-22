import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import {
  loginUser,
  dismissPostLoginPrompts,
  expectAtVault,
  createItem,
  expectItem,
} from '../helpers/vault'

const email = 'upgrade@example.com'
const preItem = 'pre-upgrade-secret'
const postItem = 'post-upgrade-secret'

test.describe('bitwarden post-upgrade', () => {
  test('login, verify pre item, create and verify post item', async ({ page }, testInfo) => {
    await loginUser(page, email)
    await shoot(page, testInfo, 'login-credentials')
    await dismissPostLoginPrompts(page)
    await expectAtVault(page)
    await expectItem(page, preItem)
    await shoot(page, testInfo, 'pre-upgrade-verified')
    await createItem(page, postItem)
    await expectItem(page, preItem)
    await expectItem(page, postItem)
    await shoot(page, testInfo, 'post-upgrade-verified')
  })
})
