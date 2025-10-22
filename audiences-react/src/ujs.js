import React, { useState, useEffect } from "react"
import ReactDOM from "react-dom"
import { AudienceEditor } from "."
import "playbook-ui/dist/reset.css"
import "playbook-ui/dist/playbook.css"
import "@fortawesome/fontawesome-free/js/all.min.js"

if (typeof window !== "undefined") {
  window.AudiencesRails = { AudienceEditor }
}

// Wrapper component to handle mobile detection
function AudienceEditorWrapper(props) {
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 768)

  useEffect(() => {
    const handleResize = () => setIsMobile(window.innerWidth <= 768)
    window.addEventListener("resize", handleResize)
    return () => window.removeEventListener("resize", handleResize)
  }, [])

  return React.createElement(AudienceEditor, {
    ...props,
    isMobile,
  })
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
          React.createElement(AudienceEditorWrapper, {
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
