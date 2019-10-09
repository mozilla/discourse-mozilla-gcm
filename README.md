# Discourse Mozilla Group and Category Management
*API to create/manage namespaced groups and categories on a Discourse instance*

## API

* [Documentation](https://mozilla.github.io/discourse-mozilla-gcm/)
* [OpenAPI document](api.yml)

## Dependencies

This plugin has a dependency on other Discourse plugins, these are:

- [`discourse-mozilla-iam`](https://github.com/mozilla/discourse-mozilla-iam/)
- [`discourse-group-category-notification`](https://github.com/mozilla/discourse-group-category-notification)

And these plugins are recommended:

- [`discourse-auto-email-in`](https://github.com/mozilla/discourse-auto-email-in)

### Archives category

This plugin requires a category called "Archives" to moved deleted categories to.

## Usage

Currently, this plugin doesn't have a UI. New clients must be created using `rails c`:

`MozillaGCM::Client.create!(name: "Test Client", namespace: "test", category: category, key: "12345")`

## Bug reports

Bug reports should be filed [by following the process described here](https://discourse.mozilla.org/t/where-do-i-file-bug-reports-about-discourse/32078).

## Running tests

Clone this plugin into `plugins/discourse-mozilla-gcm` in the root of your Discourse source dir.

Use `RAILS_ENV=test rake plugin:spec[discourse-mozilla-gcm]` to run the tests.

## Licence

[MPL 2.0](https://www.mozilla.org/MPL/2.0/)
