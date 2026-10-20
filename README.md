![demo](resources/puppet_debugger_long_white.png)

![demo](resources/animated-debugger-demo.gif)


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [puppet-debugger](#puppet-debugger)
  - [Compatibility](#compatibility)
  - [Production usage](#production-usage)
  - [Installation](#installation)
  - [Load path](#load-path)
  - [Interactive demo](#interactive-demo)
  - [Web demo](#web-demo)
  - [Usage](#usage)
  - [Using Variables](#using-variables)
    - [Listing variables](#listing-variables)
  - [Listing functions](#listing-functions)
  - [Using functions](#using-functions)
  - [Duplicate resource error](#duplicate-resource-error)
  - [Setting the puppet log level](#setting-the-puppet-log-level)
  - [Remote nodes](#remote-nodes)
    - [Setup](#setup)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
[![Gem Version](https://badge.fury.io/rb/puppet-debugger.svg)](https://badge.fury.io/rb/puppet-debugger)

# puppet-debugger

A interactive command line tool for evaluating and debugging the puppet language.

## Documentation
Please visit https://docs.puppet-debugger.com for more info.

## Compatibility
Requires Puppet 7+ or OpenVox 8+, and Ruby 2.7+. The gem has no runtime dependencies beyond
Ruby's standard library and the puppet or openvox gem, so it installs cleanly into the Ruby
shipped with the OpenVox agent, OpenBolt, and Puppet all-in-one packages.

## Production usage
The puppet debugger is a developer tool that should only be used when writing puppet code. Although it might seem useful
to install on your production puppet master, please do not; `debug::break()` refuses to start without a terminal, but
the gem has no business on a server.

## Installation
With a system Ruby:

    gem install puppet-debugger

### All-in-one (AIO) packages
The OpenVox agent and OpenBolt packages ship their own Ruby under `/opt/puppetlabs/puppet/bin` and
`/opt/puppetlabs/bolt/bin`. Install the gem with that Ruby's `gem` command and `--user-install`, which
puts it in your home directory (`~/.local/share/gem/ruby/<version>`), the one gem location the
`puppet` and `bolt` wrappers leave on the search path:

    /opt/puppetlabs/puppet/bin/gem install --user-install puppet-debugger
    /opt/puppetlabs/bolt/bin/gem install --user-install puppet-debugger

On an isolated network, download `puppet-debugger-<version>.gem` from rubygems.org elsewhere, copy
the one file across, and add `--local`:

    /opt/puppetlabs/bolt/bin/gem install --user-install --local puppet-debugger-<version>.gem

Then `puppet debugger` and `debug::break()` in Bolt plans work through the normal `puppet` and `bolt`
commands. Optional extras, installed the same way: `facterdb` for `--facterdb-filter`.

### Beside other gems
The gem declares no dependencies, so it cannot conflict with gems you have installed into the same
user directory, and other gems' constraints cannot make it unloadable. Three layouts are supported:

1. The RubyGems user directory, as above. Works with both AIO wrappers.
2. A per-project Bundler setup on the Bolt AIO that reuses the AIO's gems: in the project,
   `bundle config set --local path.system true`, set `GEM_HOME=$PWD/vendor/gems` in the environment,
   `bundle install --prefer-local` (with network), then `bundle cache`, and on the isolated host
   `bundle install --local`. Run with `bundle exec /opt/puppetlabs/bolt/bin/bolt ...`, not through
   `/usr/local/bin/bolt`, which clears `GEM_HOME`.
3. A conventional `Gemfile` for rspec-puppet or onceover, where `gem 'puppet-debugger'` is listed like any
   other gem and everything runs under `bundle exec`.

### Facts
A session started with `puppet debugger` or `puppet-debugger` needs facts for the node it pretends to be.
By default they are gathered from the machine you are on. `--facts FILE` reads them from a JSON or YAML
file instead (the output of `facter --json` or `puppet facts`, a cached facts file, or a facterdb fixture).
`--facterdb-filter FILTER` uses the optional facterdb gem to try your code against another operating system.


## Web demo
There is a web version of the [puppet-debugger](https://demo.puppet-debugger.com) online but is somewhat
limited at this time. In the future we will be adding lots of awesome features to the web debugger.

## Usage
The puppet debugger is a puppet application so once you install the gem, just fire it up using `puppet debugger`.  
If you have used `puppet apply` to evaulate puppet code, this replaces all of that with a simple debugger REPL console.
The debugger will only parse and evaluate your code.  It will not build a catalog
and try to enforce the catalog. This has a few side affects.  This means you can type any puppet code in the debugger
and see what it would actual do when compiling a resource.

1. Type and provider code will not get run.
2. Nothing is created or destroyed on your system.

`puppet debugger`

Example Usage
```
Ruby Version: 3.2.5
Puppet Version: 8.28.0
Puppet Debugger Version: 2.0.0
Created by: NWOps <corey@nwops.io>
Type "commands" for a list of debugger commands
or "help" to show the help screen.


1:>> $os
 => {
  'architecture' => 'x86_64',
  'family' => 'RedHat',
  'hardware' => 'x86_64',
  'name' => 'Fedora',
  'release' => {
    'full' => '42',
    'major' => '42'
  },
  'selinux' => {
    'config_mode' => 'permissive',
    'config_policy' => 'targeted',
    'current_mode' => 'permissive',
    'enabled' => true,
    'enforced' => false,
    'policy_version' => '29'
  }
}
2:>> 

```

## Copyright

Copyright (c) 2018 NWOPS, LLC. See LICENSE.txt for
further details.
