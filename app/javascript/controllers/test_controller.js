import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "formContainer"]

  connect() {
    console.log("AAAA connected")
  }

}