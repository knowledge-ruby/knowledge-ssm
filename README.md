# Knowledge Ssm

This is the official AWS SSM adapter for knowledge gem.

## Disclaimer

The full documentation is currently being written. You should be able to find a better documentation in a few hours or days.

Waiting for the full documentation, you can have a look at the code which is already well-documented.

Have a look to the [wiki](https://github.com/knowledge-ruby/knowledge-ssm/wiki) too.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'knowledge-ssm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knowledge-ssm

## Usage

```ruby
require 'knowledge/ssm'
  
knowledge = Knowledge::Learner.new
knowledge.variables = { ssm: { my_secret: 'path/to/secret' } }
  
knowledge.use(name: :ssm)
knowledge.add_adapter_params(adapter: :ssm, params: { root_path: '/project' })
  
knowledge.gather!
  
Knowledge::Configuration.my_secret # "Secret value"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/knowledge-ruby/knowledge-ssm. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Knowledge::Ssm project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/knowledge-ruby/knowledge-ssm/blob/master/CODE_OF_CONDUCT.md).

## Licensing

This project is licensed under [GPLv3+](https://www.gnu.org/licenses/gpl-3.0.en.html).

You can find it in LICENSE.md file.