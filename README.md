# Gaq

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

4. If you want to use custom variables, configure them like this:

    ```ruby
    class MyApplication < Rails::Application
      config.gaq.declare_variable :user_gender, scope: :session, slot: 1
    end
    ```

## Usage in the controller

For inserting a track event to be rendered on the current request, do

```ruby
gaq.push_track_event 'category', 'action', 'label'
```

If you have configured a custom variable like above, do this to set it:

```ruby
gaq.user_gender = 'female'
```

If you need to do any of these before a redirect, use these methods on `gaq.next_request`
instead of `gaq`:

```ruby
gaq.next_request.push_track_event 'category', 'action', 'label'
```

This feature uses the flash for storing _gaq items between requests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
