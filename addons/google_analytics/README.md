# Google Analytics 4 Plugin for Godot 4.x

A plugin that enables Google Analytics 4 tracking in Godot games. This plugin supports both page views and custom events with session tracking.

## Setup

1. Enable the plugin in your Godot project:
   - Copy the `addons/google_analytics` folder to your project
   - Go to Project → Project Settings → Plugins
   - Enable the "Google Analytics" plugin

2. Configure your Google Analytics credentials:
   - Go to Project → Project Settings → General
   - In the top right enable "Advanced Settings" with the toggle
   - Scroll down to "ga4" section
   - Fill in the following settings:
     - `measurement_id`: Your GA4 measurement ID (format: "G-XXXXXXXXXX")
     - `api_secret`: Your GA4 API secret (from GA4 Admin → Data Streams → Choose your stream → Measurement Protocol API secrets)
     - `not_verbose_print`: Enable logging in not verbose stdout
     - `root_url`: Used in page view event. "https://foo.bar" format
     - `referer`: Used in page view event as a referrer source

## Usage

### Tracking Page Views

```gdscript
# This will use provided title and root_url from settings
GA4.track_page_view("Home page")

# This will use provided title and root_url + path (https://foo.bar/about)
GA4.track_page_view("About page", '/about')
```

### Tracking Custom Events

```gdscript
GA4.track_event("game_launch", {
   "game_version": "1.0.0",
   "param": "value",
   "other_param": "other_value"
}) # page_location will be set to root_url

GA4.track_event(
   "custom_event",
   {
      "param_1": "1",
      "param_2": "2"
   },
   '/custom_path'
) # page_location in event params will be set to root_url + provided custom_path

GA4.track_event(
   "custom_event",
   {
      "param_1": "1",
      "param_2": "2",
      "page_location": "app://game/level1"
   },
   '/custom_path'
) # custom_path will be ingored and page_location will be taken from params

```

## License

MIT License - Feel free to use in any project, commercial or otherwise.

## Notes

The original idea came from https://github.com/englishtom/godot-google-analytics but i changed almost everything trying to adjust this plugin for my own needs. Not a fork anymore
