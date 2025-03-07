import "playbook-ui/dist/reset.css"
import "playbook-ui/dist/playbook.css"

import "@fortawesome/fontawesome-free/js/all.min.js"

import { StrictMode } from "react"
import ReactDOM from "react-dom"
import { Title } from "playbook-ui"

import { AudienceEditor } from "."

const audienceKey =
  "BAh7CEkiCGdpZAY6BkVUSSIfZ2lkOi8vZHVtbXkvRXhhbXBsZU93bmVyLzEGOwBUSSIMcHVycG9zZQY7AFRJIg5hdWRpZW5jZXMGOwBUSSIPZXhwaXJlc19hdAY7AFRJIh0yMDIzLTA5LTAyVDE4OjE1OjQxLjQxNloGOwBU--7bcda79e962d221c4820cc4afebd194d288d7dc5"

const rootNode = document.getElementById("root")
ReactDOM.render(
  <StrictMode>
    <Title>Audiences Example</Title>
    <AudienceEditor
      uri={`http://localhost:3000/audiences`}
      context={audienceKey}
    />
  </StrictMode>,
  rootNode,
)
