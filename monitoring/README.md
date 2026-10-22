# Monitoring

The monitoring server runs three components:

| Component | Port | Role |
|---|---|---|
| Prometheus | 9090 | Scrapes metrics and stores them |
| Blackbox Exporter | 9115 | Probes URLs over HTTP and reports success and response time |
| Grafana | 3000 | Dashboards on top of Prometheus (*Prometheus Blackbox Exporter* dashboard) |

Prometheus asks Blackbox Exporter to probe the application's load balancer URL with the `http_2xx` module, so a probe is a success when the application returns an HTTP 2xx response.

`prometheus.yml` is a reference scrape configuration **reconstructed from the Prometheus Targets page** (screenshot `18-prometheus-target-health.png`), because the original file was not saved. Replace `<monitoring-server-ip>` with the host running Blackbox Exporter and the ELB hostname with your own.

After changing the config, reload Prometheus (restart it or call its reload endpoint) and check **Status, Target health**.

Do not expose Prometheus, Blackbox Exporter or Grafana to the public internet without access controls.
