# Render blueprint for Prometheus

A wrapper-based docker service for your Render blueprints. This allows setting
up a Prometheus instance scrapping your other services.

## Quickstart

Add this service in your `render.yaml`

```yaml
- type: worker
  name: prometheus
  runtime: docker
  repo: https://github.com/autometrics-dev/render-prometheus
  dockerContext: ./docker
  envVars:
    # Setting root/global options for Prometheus configuration
    - key: PROM_GLOBAL_OPTS
      value: "global.scrape_interval=3s;global.scrape_timeout=1s;global.external_labels.monitor=Render;rule_files.1=/mount/rules/*.yml"
    # Setting up a Front-end target
    - key: PROM_TARGET_FRONT_END
      fromService:
        type: web
        name: front-end
        property: hostport
    - key: PROM_OPTS_FRONT_END
      value: "scheme=https;metrics_path=/prometheus"
    # Setting up a Back-end target
    - key: PROM_TARGET_BACK_END
      fromService:
        type: web
        name: back-end
        property: hostport
    - key: PROM_OPTS_BACK_END
      value: "honor_labels=true"
```

## Options

Manipulating the configuration for Prometheus all come down to using
environment variables.

### Configuring monitored targets

All flags are passed as environment variables. When they allow multiple values,
they are separated by `;`.

Key-value pairs in `;` separated lists have a `=` sign between the key and the
value: `key=value`. The pairs are split on the first `=` only, so passing
`aie=joé=tsr` will become a pair with `aie` as the key, and `joé=tsr` as the
value.

Keys are `.` separated path into the configuration. For example, to target the
global `scrape_interval` in a configuration, you must use `global.scrape_interval`.

For values that are lists, like `alerting.alertmanagers`, you can use integers to
target elements in the list (it will auto append a new element if the index is
exactly the next available element): `alerting.alertmanagers.0.timeout=2s` will set
the timeout of the first alertmanager to `2s`, creating it if necessary.

integers, floating-point numbers, and `true`/`false` are interpreted as numbers and
booleans by default. To have actual strings for those values, wrap these values in `""`:
`honor_labels=true` affects a boolean to `honor_labels`, whereas
`alerting.alertmanagers.0.api_version="true"` affects a string to `api_version`.


#### Global flags

Flags that do not concern the scrape targets must go in `PROM_GLOBAL_OPTS`. This environment variable
contains a list of `=` key-value pairs that define the values to use for each key we want non-default.

#### Per target flag

To define a new target, you can choose any name (let's say `nitrogen`), and then
build environment variables that allow creating a monitorng job for prometheus
with that name:

- `PROM_TARGET_NITROGEN` is a `;`-separated list of the targets to scrape for
  this job. This environment variable is separate from the rest to allow reusing
  the `hostport` variable from `fromService` in Blueprints.
- `PROM_OPTS_NITROGEN` is a list of options that will go under the
  `scrape_config` with `job_name: nitrogen`. This allows for example to set the
  `scheme` or the `metrics_path` for a monitoring job.

### Passing flags to Prometheus

All the command line arguments passed to the image are given as-is to the
prometheus instance being wrapped. Note that using `config.file` and 
`web.listen-address` flags is forbidden, as:
- `config.file` is hardcoded to use the generated configuration from
  environment variables, and
- `web.listen-address` is hardcoded to listen to `$PORT` on all interfaces
  (`0.0.0.0`) so that Prometheus is correctly detected by Render.

## Limitations

### Autoscaled services

Currently, Render does not give access to [per-instance
metrics](https://feedback.render.com/features/p/per-instance-metrics-for-multi-instance-services),
therefore the metrics collected here will only work on single-instance
services.

**Targeting multi-instance services will produce semi-random data (because of load-balancing) and produce wrong alerts/SLOs**

### Pulling metrics

This service will only work with scraping metrics for now, as it's the
recommended way to deal with long running services, notably to have
better uptime metrics and control data usage.

### Prometheus does not work on Free Tier

_Technically_ Prometheus works, but with instances shutting down after some
inactivity, it makes everything unreliable:
- the Prometheus instance itself might shutdown, and lose all its data (free
  tier doesn't have access to persistent disks).
- once shutdown, the restart of Prometheus might take time, and
- the monitored services can also shutdown, and then Prometheus will mark the
  services as down, as the `/metrics` endpoint response time gets longer than
  the configured
  [scrape_timeout](https://prometheus.io/docs/prometheus/latest/configuration/configuration)


## TODO

- [ ] Set up [file-based service discovery](https://prometheus.io/docs/guides/file-sd/#use-file-based-service-discovery-to-discover-scrape-targets) somehow.

## Open questions

- Are we sure that the service is going to be restarted if the `hostport` changes?
- If the service restarts, are we guaranteed to keep the extra data?
- How can we make it so Prometheus is never restarted, but instead call its
  reload-config endpoint when something changes in the configuration?
  + Use service discovery
- Is it possible to update the configuration externally?
  + Use service discovery, again
