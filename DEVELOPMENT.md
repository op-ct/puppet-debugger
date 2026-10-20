## Testing

Standard setup with a system Ruby:

    bundle install
    bundle exec puppet module install puppetlabs-stdlib
    bundle exec rspec

Set `USE_OPENVOX=true` to test against the openvox gem instead of puppet, and `PUPPET_GEM_VERSION`
to pick a version of either.

### With an all-in-one Ruby
Without a system Ruby you can run the suite with OpenBolt's Ruby and reuse the gems it ships:

    export GEM_HOME=$PWD/vendor/gems           # project gems go here; the AIO's stay read-only
    export PATH=/opt/puppetlabs/bolt/bin:$PATH
    bundle config set --local path.system true
    USE_OPENVOX=true bundle install --prefer-local
    USE_OPENVOX=true bundle exec puppet module install puppetlabs-stdlib
    USE_OPENVOX=true bundle exec rspec

`--prefer-local` keeps the AIO's version of gems named in the Gemfile; transitive gems may still resolve
to newer releases than the AIO has, which costs a native build for a few of them.

To try the debugger from the checkout without installing it:

    RUBYLIB=lib puppet debugger


## Plugin Development
 * [Plugin Development Guide](Plugin_development.md)
 