import React from "react"
import ReactDOM from "react-dom"
import { AudienceEditor } from "."

if (typeof window !== "undefined") {
  window.AudiencesRails = { AudienceEditor }
}

function mountAudiencesEditors() {
  document
    .querySelectorAll("[data-react-class='AudiencesEditor']")
    .forEach((element) => {
      if (!element.dataset.reactMounted) {
        const uri = element.dataset.audiencesUri
        const context = element.dataset.audiencesContext
        element.dataset.reactMounted = true

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
