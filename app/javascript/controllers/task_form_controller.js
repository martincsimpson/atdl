import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "delegateForm", "deferForm", "moveForm", "updateSnoozeForm", "notesForm"]

  connect() {
    console.log("TaskFormController connected")
  }

  addForm(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute("data-url")
    const targetId = event.currentTarget.getAttribute("data-target-id")

    console.log("Adding form for URL: ", url)
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        console.log("Turbo Stream HTML received: ", html)
        const targetElement = document.getElementById(targetId)
        if (targetElement) {
          console.log(`Inserting HTML into target element with ID: ${targetId}`)
          targetElement.innerHTML = html
        } else {
          console.error(`Target element with ID ${targetId} not found`)
        }
      })
      .catch(error => console.error("Error fetching form: ", error))
  }

  showDelegateForm(event) {
    event.preventDefault()
    this.delegateFormTarget.classList.remove("hidden")
  }

  showDeferForm(event) {
    event.preventDefault()
    this.deferFormTarget.classList.remove("hidden")
  }

  showMoveForm(event) {
    event.preventDefault()
    this.addForm(event) // Fetch and display the form dynamically
    this.moveFormTarget.classList.remove("hidden")
  }

  showSnoozeForm(event) {
    event.preventDefault()
    this.updateSnoozeFormTarget.classList.remove("hidden")
  }
 
  showNotesForm(event) {
    event.preventDefault()
    this.notesFormTarget.classList.remove("hidden")
  }
}