# fluent-plugin-http-content-negotiation

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-http-content-negotiation.svg)](https://badge.fury.io/rb/fluent-plugin-http-content-negotiation)

# NOTE: This plugin is no longer maintained

The plugin still works, as of last use, but it is no longer maintained or in use due to Heroku/DataDog native log drains

# Introduction

This is a [fluent](https://fluentd.org) input plugin to accept Heroku HTTPS
log drains.

This plugin is heavily derived from hakobera/fluent-plugin-heroku-syslog
and includes code from the dblN/fluent-plugin-heroku-syslog and
gmile/fluent-plugin-heroku-syslog forks of that code. Unlike that plugin,
this plugin focuses exclusively on HTTPS log drains and gets its tags from
the request PATH, rather than configuration. This allows the input to more
easily be integrated into complex pipelines.

## Installation

Install with `gem` or `td-agent-gem` commands:
```
# using fluentd/gem
$ gem install fluent-plugin-http-content-negotiation

# using td-agent
$ td-agent-gem install fluent-plugin-http-content-negotiation
```

Install using `bundler` in Gemfile:
```
gem 'fluent-plugin-http-content-negotiation'
```

## Configuration

This plugin implements HttpContentNegotiationInput which extends the built-in HttpInput
plugin to accept RFC-5424 formatted syslog messages, framed using syslog TCP
protocol octet counting framing method from RFC-6587, from [Heroku HTTPS
drains](https://devcenter.heroku.com/articles/log-drains#https-drains). This
plugin support all of the `in_http` plugin configuration parameters.

### Basic configuration

```
<source>
  @type heroku_http
  port 9880
</source>
```

### Filtered by drain IDs

```
<source>
  @type heroku_http
  port 9880
  drain_ids ["YOUR-HEROKU-DRAIN-ID","ANOTHER-HEROKU-DRAIN-ID"]
</source>
```

### Heroku configuration

The fluent tag is parsed from the input request PATH, in the same way as the
[in_http](https://docs.fluentd.org/v1.0/articles/in_http#basic-usage) plugin.

```
# add logdrain to heroku application
$ heroku drains:add https://YOUR-FLUENTD-HOST/DESIRED-FLUENT-TAG
```


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FApplauseOSS%2Ffluent-plugin-http-content-negotiation.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FApplauseOSS%2Ffluent-plugin-http-content-negotiation?ref=badge_large)
