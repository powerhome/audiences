# frozen_string_literal: true

module Audiences
  module EditorHelper
    def render_audiences_editor(uri, context, html_class: "audiences-editor")
      content_tag(:div, "",
                  data: {
                    react_class: "AudiencesEditor",
                    audiences_uri: uri,
                    audiences_context: context,
                  },
                  class: html_class)
    end
  end
end
