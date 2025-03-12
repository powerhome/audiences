import React from "react"
import ReactDOM from "react-dom"

function mountAudiencesEditors() {
  document
    .querySelectorAll("[data-react-class='AudiencesEditor']")
    .forEach((element) => {
      if (!element.dataset.reactMounted) {
        const uri = element.dataset.audiencesUri
        const context = element.dataset.audiencesContext

        ReactDOM.render(
          React.createElement(window.AudiencesRails.AudienceEditor, {
            uri,
            context,
          }),
          element,
        )
      }
    })
}

document.addEventListener("DOMContentLoaded", mountAudiencesEditors)
document.addEventListener("turbo:load", mountAudiencesEditors)
document.addEventListener("turbo:render", mountAudiencesEditors)
