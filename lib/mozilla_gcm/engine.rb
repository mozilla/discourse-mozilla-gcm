module MozillaGCM
  class Engine < ::Rails::Engine
    engine_name "MozillaGCM".freeze
    isolate_namespace MozillaGCM

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::MozillaGCM::Engine, at: "/mozilla_gcm"
      end
    end
  end
end
