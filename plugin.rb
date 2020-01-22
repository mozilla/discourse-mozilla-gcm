# name: mozilla-gcm
# about: API to create/manage namespaced groups and categories on a Discourse instance
# version: 0.1.4
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-mozilla-gcm

PLUGIN_NAME ||= "MozillaGCM".freeze

load File.expand_path('../lib/mozilla_gcm/engine.rb', __FILE__)
load File.expand_path('../lib/mozilla_gcm/api_helpers.rb', __FILE__)
