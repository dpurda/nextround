import { Controller } from "@hotwired/stimulus"

// Generic add/remove for Rails nested_attributes forms, without a gem.
// Usage: wrap each existing row and the <template> in [data-nested-form-target="container"],
// give the <template> content a data-nested-form-target="template" attribute, and put
// "NEW_RECORD" in the template's field names/ids where Rails would put the record's index.
export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")

    if (row.dataset.newRecord === "true") {
      row.remove()
      return
    }

    row.querySelector("input[name*='[_destroy]']").value = "1"
    row.hidden = true
  }
}
