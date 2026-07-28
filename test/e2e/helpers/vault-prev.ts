import { Page, expect } from '@playwright/test'

export const MASTER_PASSWORD = 'Ngpqy8Bfk123'

async function gotoAndWaitFor(page: Page, anchorSelector: string) {
  for (let attempt = 0; attempt < 4; attempt++) {
    if (attempt === 0) {
      await page.goto('/')
    } else {
      await page.reload()
    }
    try {
      await page.locator(anchorSelector).first().waitFor({ state: 'visible', timeout: 30_000 })
      return
    } catch {
      // bundle may have 502'd on cold-start nginx upstream; retry
    }
  }
  await page.locator(anchorSelector).first().waitFor({ state: 'visible', timeout: 30_000 })
}

export async function registerUser(page: Page, email: string) {
  await gotoAndWaitFor(page, 'a:has-text("Create account")')
  await page.locator('a:has-text("Create account")').click()
  await page.locator('#register-start_form_input_email').fill(email)
  await page.locator('#register-start_form_input_name').fill('Test User')
  await page.locator('button[type="submit"]').click()
  await page.locator('#input-password-form_new-password').fill(MASTER_PASSWORD)
  await page.locator('#input-password-form_new-password-confirm').fill(MASTER_PASSWORD)
  await page.locator('button[type="submit"]').click()
}

export async function loginUser(page: Page, email: string) {
  await page.goto('/')
  await page.context().clearCookies()
  await page.evaluate(() => { localStorage.clear(); sessionStorage.clear() })
  await gotoAndWaitFor(page, '[data-testid="login-email-input"]')
  await page.getByTestId('login-email-input').fill(email)
  await page.getByTestId('login-continue-button').click()
  await page.getByTestId('login-master-password-input').fill(MASTER_PASSWORD)
  await page.getByTestId('login-submit-button').click()
}

export async function dismissPostLoginPrompts(page: Page) {
  for (const text of ['Add it later', 'Skip to web app']) {
    try {
      await page.getByText(text, { exact: false }).first().click({ timeout: 15_000 })
    } catch {
      // prompt not shown in this flow
    }
  }
  try {
    await page.getByRole('button', { name: 'Skip', exact: true }).click({ timeout: 15_000 })
  } catch {
    // onboarding tour not shown in this flow
  }
  await page
    .locator('.cdk-overlay-backdrop')
    .first()
    .waitFor({ state: 'detached', timeout: 15_000 })
    .catch(() => {})
}

export async function expectAtVault(page: Page) {
  await expect(
    page.locator('h1:has-text("All vaults"), h3:has-text("All vaults")').first()
  ).toBeVisible({ timeout: 30_000 })
}

export async function createItem(page: Page, name: string) {
  await page.locator('button#newItemDropdown').click()
  await page.locator('bit-menu-item:has-text("Login"), button[role="menuitem"]:has-text("Login")').first().click()
  await page.locator('input[formcontrolname="name"]').fill(name)
  await page.locator('button:has-text("Save")').click()
  await page.locator('button[aria-label="Close"], button[title="Close"], button.close').first().click()
}

export async function expectItem(page: Page, name: string) {
  const escaped = name.replace(/"/g, '\\"')
  await expect(
    page.locator(
      `td:has-text("${escaped}"), app-vault-items-list :has-text("${escaped}"), cdk-virtual-scroll-viewport :has-text("${escaped}")`
    ).first()
  ).toBeVisible({ timeout: 30_000 })
}
