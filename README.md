NO LONGER MAINTAINED

# Gaq [![Code Climate](https://codeclimate.com/github/schnittchen/gaq.png)](https://codeclimate.com/github/schnittchen/gaq) [![Build Status](https://travis-ci.org/schnittchen/gaq.png)](https://travis-ci.org/schnittchen/gaq) [![Coverage Status](https://coveralls.io/repos/schnittchen/gaq/badge.png?branch=master)](https://coveralls.io/r/schnittchen/gaq?branch=master)

Ever wanted to push a track event from a controller? Set a custom variable from model data? Now you can.

## Installation

Add this line to your application's Gemfile:

    gem 'gaq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gaq

## Setup

1. Require `gaq` from your `application.rb` and configure your web_property_id like this:

    ```ruby
    class MyApplication < Rails::Application
      config.gaq.web_property_id = 'UA-XXYOURID-1'
    end
	```

2. Put this in your application layout:

    ```ruby
    <%= render_gaq %>
    ```

    This inserts javascript code for initializing _gaq, your tracking events and the ga.js snippet.
    The ga.js snippet will only be rendered in the production environment, so no real tracking happens
    during development.

3. DONE!

### More setup

If you want to use custom variables, configure them like this:

```ruby
  config.gaq.declare_variable :user_gender, scope: :session, slot: 1
```

If you need the _anonymizeIp feature, enable it like this:

```ruby
  config.gaq.anonymize_ip = true
```

## Usage in the controller

For inserting a track event to be rendered on the current request, do

```ruby
gaq.track_event 'category', 'action', 'label'
```

If you have configured a custom variable like above, do this to set it:

```ruby
gaq.user_gender = 'female'
```

If you need to do any of these before a redirect, use these methods on `gaq.next_request`
instead of `gaq`:

```ruby
gaq.next_request.track_event 'category', 'action', 'label'
```

This feature uses the flash for storing _gaq items between requests.

## Supported tracker commands

Currently, only _trackEvent and _setCustomVar is supported. However commands are easily added, so open a pull request!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Testing

Test dependencies are declared in the Gemfile.
All specs are run from guard.

The most interesting part is the controller_handle_spec, it asserts what commands get rendered under which circumstances.

There is a dummy rails application
in `spec-dummy` for integration tests, which we need because gaq keeps state in
the session. The integration specs are located inside of it.

It has two test environments, `test_static` and `test_dynamic`. Specs tagged with
`:static` will not be run under `test_dynamic` and vice versa. The dynamic tests are for dynamic configuration items, which is an upcoming feature that lets you configure things dynamically in the context of the running controller.
