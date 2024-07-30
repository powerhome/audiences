import * as ReactDOM from "react-dom";
import React from "react";
import { AudienceEditor } from "audiences";

import "@fortawesome/fontawesome-free/js/all.min.js";

class AudienceEditorComponent extends HTMLElement {
  connectedCallback() {
    const mountPoint = document.createElement('div');
    this.appendChild(mountPoint);

    const uri = this.getAttribute('uri');
    const scimUri = this.getAttribute('scim');

    ReactDOM.render(
      React.createElement(AudienceEditor, { uri, scimUri }),
      mountPoint
    );
  }
}
customElements.define('audiences-editor', AudienceEditorComponent);
