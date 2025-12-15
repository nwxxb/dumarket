import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["burgerButton", "navbarMenu"];
  static classes = ["isUnfolded"];

  toggle(event) {
    event.preventDefault();
    const isUnfoldedFlag = this.burgerButtonTarget.classList.toggle(
      this.isUnfoldedClass,
    );
    this.navbarMenuTarget.classList.toggle(this.isUnfoldedClass);
    this.burgerButtonTarget.setAttribute(
      "aria-expanded",
      isUnfoldedFlag.toString(),
    );
  }
}
