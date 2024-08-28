import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "details"]

  connect() {
    console.log("ProjectFormController connected123")
    this.collapsed = false
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
      .then(response => {
        console.log("Response Status: ", response.status)
        return response.text()
      })
      .then(html => {
        console.log("Turbo Stream HTML received: ", html)
        const targetElement = document.getElementById(targetId)
        if (targetElement) {
          console.log(`Inserting HTML into target element with ID: ${targetId}`)
          targetElement.innerHTML = html;
        } else {
          console.error(`Target element with ID ${targetId} not found`)
        }
      })
      .catch(error => console.error("Error fetching form: ", error))
  }

  toggle() {
    console.log("Toggle clicked")
    this.collapsed = !this.collapsed
    this.detailsTarget.classList.toggle("hidden", this.collapsed)
    this.element.querySelector(".toggle-button").textContent = this.collapsed ? "+" : "-"

    // Make an API call to update the hidden state
    const projectId = this.element.id.split("_")[1]
    fetch(`/projects/${projectId}/toggle_hidden`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
      },
      body: JSON.stringify({ hidden: this.collapsed })
    })
    .then(response => response.json())
    .then(data => {
      console.log("Project hidden state updated:", data)
    })
    .catch(error => console.error("Error updating project hidden state:", error))
  }

}