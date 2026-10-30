
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "confirmation"]

  async submit(event) {
    event.preventDefault()

    const form = this.element
    const selected = form.querySelectorAll(
      ".push-checkbox:checked"
    )

    if (selected.length === 0) {
      alert("Please select at least one product.")
      return
    }

    if (!this.confirmationTarget.checked) {
      alert("Please confirm before publishing.")
      return
    }

    if (!window.confirm(
      `Push ${selected.length} selected products to Shopify?`
    )) {
      return
    }

    const button = this.buttonTarget
    button.disabled = true
    button.textContent = "Pushing to Shopify..."

    try {
      const headers = {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }

      const csrfToken = document.querySelector(
        'meta[name="csrf-token"]'
      )?.content

      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken
      }

      if (document.querySelector(
        'meta[name="shopify-api-key"]'
      )) {
        if (!window.shopify?.idToken) {
          throw new Error(
            "Shopify App Bridge is not initialized."
          )
        }

        const token = await window.shopify.idToken()
        headers["Authorization"] = `Bearer ${token}`
      }

      const response = await fetch(form.action, {
        method: "POST",
        headers: headers,
        body: new FormData(form),
        credentials: "same-origin",
        redirect: "error"
      })

      if (!response.ok) {
        throw new Error(
          `Publishing failed: HTTP ${response.status}`
        )
      }

      const html = await response.text()
      const page = new DOMParser().parseFromString(
        html,
        "text/html"
      )

      const newContent = page.querySelector("main.main")
      const currentContent = document.querySelector(
        "main.main"
      )

      if (!newContent || !currentContent) {
        throw new Error(
          "Publishing response page could not be displayed."
        )
      }

      currentContent.replaceWith(newContent)

    } catch (error) {
      console.error("Shopify push error:", error)

      alert(
        `${error.message}\n\nCheck Render logs and Shopify Products before retrying.`
      )

      if (button.isConnected) {
        button.disabled = false
        button.textContent = "Confirm & Push to Shopify"
      }
    }
  }
}
