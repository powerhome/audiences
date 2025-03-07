import React from "react";
import ReactDOM from "react-dom";
import AudiencesEditor from "audiences-react";

function mountAudiencesEditors() {
  document.querySelectorAll("[data-react-class='AudiencesEditor']").forEach((element) => {
    if (!element.dataset.reactMounted) {
      const uri = element.dataset.audiencesUri;
      const context = element.dataset.audiencesContext;
      ReactDOM.render(<AudiencesEditor uri={uri} context={context} />, element);
      element.dataset.reactMounted = "true";
    }
  });
}

document.addEventListener("DOMContentLoaded", mountAudiencesEditors);
document.addEventListener("turbo:load", mountAudiencesEditors);
document.addEventListener("turbo:render", mountAudiencesEditors);
