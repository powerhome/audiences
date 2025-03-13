import "./audiencesEditor"
import React from "react"
import ReactDOM from "react-dom"
import { AudienceEditor } from "."

declare global {
  interface Window {
    AudiencesRails?: {
      AudienceEditor: typeof AudienceEditor
    }
  }
}

if (typeof window !== "undefined") {
  window.React = React
  window.ReactDOM = ReactDOM
  window.AudiencesRails = { AudienceEditor }
}
