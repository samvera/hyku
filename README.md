# Hyku, the Hydra-in-a-Box Repository Application

Code: 
[![Build Status](https://travis-ci.org/samvera-labs/hyku.svg)](https://travis-ci.org/samvera-labs/hyku)
[![Coverage Status](https://coveralls.io/repos/samvera-labs/hyku/badge.svg?branch=master&service=github)](https://coveralls.io/github/samvera-labs/hyku?branch=master)
[![Stories in Ready](https://img.shields.io/waffle/label/samvera-labs/hyku/ready.svg)](https://waffle.io/samvera-labs/hyku)

Docs: 
[![Documentation](http://img.shields.io/badge/DOCUMENTATION-wiki-blue.svg)](https://github.com/samvera-labs/hyku/wiki)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump In: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

----
## Table of Contents

  * [Running the stack](#running-the-stack)
    * [For development](#for-development)
    * [For testing](#for-testing)
    * [On AWS](#on-aws)
    * [With Docker](#with-docker)
    * [With Vagrant](#with-vagrant)
  * [Switching accounts](#switching-accounts)
  * [Development dependencies](#development-dependencies)
    * [Postgres](#postgres) 
  * [Importing](#importing)
    * [from CSV](#from-csv)
    * [from purl](#from-purl)
  * [Compatibility](#compatibility)
  * [Product Owner](#product-owner)
  * [Help](#help)
  * [Acknowledgments](#acknowledgments)

----

## Running the stack

### For development

```bash
docker-compose up -d
```

## Dory
Dory is a useful tool to manage the IP adresses and ports of the apps you are running locally for development.

### Directory Name
The VIRTUAL_HOST set in the docker-compose.yml file must match the name of the directory if you use default Dory settings, or match your Dory Config.  In our case, we'll assume that the directory is named "palni".  See docker-compose.yml  services:web:environment: for how your VIRTUAL_PORT is set.

### Install Dory
```bash
gem install dory
```

### And run from your project directory
```
dory up
```

Then the app is available at "http://pals.docker" or whatever the directory name you chose is.

# Developing

## Switching accounts
The recommend way to switch your current session from one account to another is by doing:

```ruby
AccountElevator.switch!('repo.example.com')
```

# Everything below may be stale

## Importing
### from CSV:

```bash
./bin/import_from_csv localhost spec/fixtures/csv/gse_metadata.csv ../hyku-objects
```

### from purl:

```bash
./bin/import_from_purl ../hyku-objects bc390xk2647 bc402fk6835 bc483gc9313
```

## Compatibility

* Ruby 2.4 or the latest 2.3 version is recommended.  Later versions may also work.
* Rails 5 is required. We recommend the latest Rails 5.1 release.

### Product Owner

[orangewolf](https://github.com/orangewolf)

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Acknowledgments

This software was developed by the Hydra-in-a-Box Project (DPLA, DuraSpace, and Stanford University) under a grant from IMLS. 

This software is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

