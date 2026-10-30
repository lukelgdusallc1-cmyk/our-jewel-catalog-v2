
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "product", "count"]

  connect() {
    this.updateCount()
  }

  toggleAll() {
    this.productTargets.forEach(checkbox => {
      if (!checkbox.disabled) {
        checkbox.checked = this.allTarget.checked
      }
    })

    this.updateCount()
  }

  updateCount() {
    const enabled = this.productTargets.filter(
      checkbox => !checkbox.disabled
    )

    const selected = enabled.filter(
      checkbox => checkbox.checked
    ).length

    this.countTarget.textContent =
      `${selected} products selected`

    this.allTarget.checked =
      enabled.length > 0 &&
      selected === enabled.length

    this.allTarget.indeterminate =
      selected > 0 && selected < enabled.length
  }
}
