import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "confirmation"]

  submit(event) {
    const selected = this.element.querySelectorAll(
      ".push-checkbox:checked"
    )

    if (selected.length === 0) {
      event.preventDefault()
      alert("Please select at least one product.")
      return
    }

    if (!this.confirmationTarget.checked) {
      event.preventDefault()
      alert("Please confirm before publishing.")
      return
    }

    const approved = window.confirm(
      `Push ${selected.length} selected products to Shopify?`
    )

    if (!approved) {
      event.preventDefault()
      return
    }

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Pushing to Shopify..."
  }
}