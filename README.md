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
    - key: PROM_TARGET_FRONT_END
      fromService:
        type: web
        name: front-end
        property: hostport
    - key: PROM_TARGET_BACK_END
      fromService:
        type: web
        name: back-end
        property: hostport
```

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

## Open questions

- Are we sure that the service is going to be restarted if the `hostport` changes?
- If the service restarts, are we guaranteed to keep the extra data?
- How can we make it so Prometheus is never restarted, but instead call its
  reload-config endpoint when something changes in the configuration?
- Is it possible to update the configuration externally?
