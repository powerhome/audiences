# frozen_string_literal: true

module Audiences
  module EditorHelper
    def render_audiences_editor(context, html_class: "audiences-editor",
                                uri: Audiences::Engine.routes.url_helpers.root_path)
      content_tag(:div, "",
                  data: {
                    react_class: "AudiencesEditor",
                    audiences_uri: uri,
                    audiences_context: context.signed_key,
                    allow_match_all: allow_match_all,
                    allow_individuals: allow_individuals,
                  },
                  class: html_class)
    end
  end
end
