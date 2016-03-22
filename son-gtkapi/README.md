# Gatekeeper's API
This folder has the code and tests for the Gatekeeper's API.

## Configuration

## Tests
Testing is done with the ```RSpec``` framework.

To support ```XML``` reports, the ```[ci_reporter](https://github.com/ci-reporter/ci_reporter)``` ```gem``` was used. You can run tests by invoking

```sh
$ bundle exec rake ci:all
```

## Usage
To use this application, we write
```sh
$ foreman start
```

```[Foreman](https://github.com/ddollar/foreman)``` is a ```ruby gem``` for managing applications based on a ```Procfile```. In our case, this file has, at the moment of writing, the following content:

```sh
web: bundle exec rackup -p $PORT
```

If the environment variable ```PORT``` is not defined, ```5000``` is assumed.