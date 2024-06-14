import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "formContainer"]

  connect() {
    console.log("InlineEditController connected to:", this.element)
    this.hideForm()
  }

  edit() {
    console.log("Edit triggered for:", this.element)
    this.displayTarget.classList.add("hidden")
    this.formContainerTarget.classList.remove("hidden")
  }

  save(event) {
    event.preventDefault()
    console.log("Save triggered for:", this.element)
    if (typeof this.formTarget.requestSubmit === "function") {
      this.formTarget.requestSubmit()
    } else {
      this.formTarget.submit()
    }
  }

  cancel(event) {
    event.preventDefault()
    console.log("Cancel triggered for:", this.element)
    this.hideForm()
  }

  hideForm() {
    console.log("Hide form for:", this.element)
    this.displayTarget.classList.remove("hidden")
    this.formContainerTarget.classList.add("hidden")
  }

  success(event) {
    console.log("Success triggered for:", this.element)
    this.hideForm()
  }
}