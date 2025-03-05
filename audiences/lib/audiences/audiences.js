import React from "react";
import ReactDOM from "react-dom";
import AudiencesEditor from "audiences-react";

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-react-class='AudiencesEditor']").forEach((element) => {
    const uri = element.dataset.audiencesUri;
    const context = element.dataset.audiencesContext;
    ReactDOM.render(<AudiencesEditor uri={uri} context={context} />, element);
  });
});
