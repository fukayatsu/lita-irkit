# lita-irkit

Use IRKit on Lita

[![Build Status](https://travis-ci.org/fukayatsu/lita-irkit.svg?branch=master)](https://travis-ci.org/fukayatsu/lita-irkit)

## Installation

Add lita-irkit to your Lita instance's Gemfile:

``` ruby
gem "lita-irkit"
```


## Configuration

```
config.handlers.irkit.deviceid  = ENV["IRKIT_DEVICEID"]
config.handlers.irkit.clientkey = ENV["IRKIT_CLIENTKEY"]
```

## Usage

```
route /^ir list/,            :ir_list,         command: false, help: { "ir list"                      => "list irkit command names" }
route /^ir send (.+)/,       :ir_send,         command: false, help: { "ir send [command_name]"       => "send irkit command" }
route /^ir all off/,         :ir_send_all_off, command: false, help: { "ir all off"                   => "send irkit commands which end with 'off'" }
route /^ir register (.+)/,   :ir_register,     command: true,  help: { "ir register [command_name]"   => "register irkit command" }
route /^ir unregister (.+)/, :ir_unregister,   command: true,  help: { "ir unregister [command_name]" => "unregister irkit command" }
route /^ir migrate/,         :ir_migrate,      command: true
```

## Migration from 0.0.x to 0.1.0
Since Redis namespace has been changed at v0.1.0, You must run migration command when upgrading to v0.1.0 or later.

```
@your_bot ir migrate
#=> :ok_woman: 10 keys are migrated.
```

## License

[MIT](http://opensource.org/licenses/MIT)
