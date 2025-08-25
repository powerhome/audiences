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
        const allowIndividuals = element.dataset.allowIndividuals != "false"
        const allowMatchAll = element.dataset.allowMatchAll != "false"
        element.dataset.reactMounted = true

        ReactDOM.render(
          React.createElement(window.AudiencesRails.AudienceEditor, {
            uri,
            context,
            allowIndividuals,
            allowMatchAll,
          }),
          element,
        )
      }
    })
}

document.addEventListener("DOMContentLoaded", mountAudiencesEditors)
document.addEventListener("turbo:load", mountAudiencesEditors)
document.addEventListener("turbo:render", mountAudiencesEditors)
