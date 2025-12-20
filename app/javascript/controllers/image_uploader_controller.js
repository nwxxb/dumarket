import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="image-uploader"
export default class extends Controller {
  static targets = ["preview"];

  fileOnChange(event) {
    let element = this.previewTarget;
    let reader = new FileReader();

    reader.onloadend = function () {
      element.src = reader.result;
    };

    reader.readAsDataURL(event.target.files[0]);
  }
}
