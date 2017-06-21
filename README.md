# VkontakteWallBackup

Save VK posts as PDF files.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vkontakte_wall_backup'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vkontakte_wall_backup

And update webdriver:

    $ geckodriver-update

Required dependencies:

    $ sudo apt-get install xdotool ghostscript firefox

## Usage

    export VK_ACCESS_TOKEN="see vk.com/dev/service_token"
    bundle exec vkontakte_wall_backup map.yml


## Contributing

1. Fork it ( https://github.com/[my-github-username]/vkontakte_wall_backup/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
