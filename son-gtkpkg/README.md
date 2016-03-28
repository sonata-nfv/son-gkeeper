# Gatekeeper's API
This folder has the code and tests for the Gatekeeper's API.

## Configuration

## Tests
Testing is done with the ```RSpec``` framework.

To support ```XML``` reports, the [ci_reporter](https://github.com/ci-reporter/ci_reporter) ```gem``` was used. You can run tests by invoking

  $ bundle exec rake ci:all

## Usage

    $ bundle exec ruby app.rb
