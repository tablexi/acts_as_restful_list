#!/bin/sh

set -e

gem list --local bundler | grep bundler || gem install bundler --no-ri --no-rdoc

echo 'Running bundle exec rspec spec against activesupport / activerecord 5.1.7...'

AARL_ACTIVERECORD_VERSION=5.1.7 bundle update activerecord
bundle exec rspec spec

echo 'Running bundle exec rspec spec against activesupport / activerecord 5.2.3...'

AARL_ACTIVERECORD_VERSION=5.2.3 bundle update activerecord
bundle exec rspec spec

echo 'Success!'
