import * as ReactDOM from "react-dom";
import React from "react";
import { AudienceEditor } from "audiences";

import "@fortawesome/fontawesome-free/js/all.min.js";

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("div[data-audiences-uri]").forEach((element) => {
    const uri = element.getAttribute("data-audiences-uri");
    const context =  element.getAttribute("data-audiences-context");

    ReactDOM.render(
      React.createElement(AudienceEditor, { uri, context }),
      element
    );
  });
});
