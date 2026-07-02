# nginx_gateway_fabric

Cloud-agnostic base module for [NGINX Gateway Fabric](https://github.com/nginxinc/nginx-gateway-fabric) (v2.6.5) using the Kubernetes Gateway API.

This module is designed to be called by cloud-specific flavor modules (AWS, GCP, Azure, OVH) that pass their own LB annotations and proxy configuration.

## Usage

```hcl
module "nginx_gateway_fabric" {
  source = "github.com/Facets-cloud/facets-utility-modules//nginx_gateway_fabric"

  instance      = var.instance
  instance_name = var.instance_name
  environment   = var.environment
  inputs        = var.inputs

  # Cloud-specific overrides
  service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  }

  nginx_proxy_extra_config = {
    rewriteClientIP = {
      mode = "ProxyProtocol"
      trustedAddresses = [{ type = "CIDR", value = "0.0.0.0/0" }]
    }
  }
}
```

## Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `instance` | `any` | — | yes | Facets instance object (must contain `spec`) |
| `instance_name` | `string` | — | yes | Architectural name of the ingress instance |
| `environment` | `any` | — | yes | Environment context (must contain `unique_name` and `namespace`) |
| `inputs` | `object` | — | yes | Module inputs (see `variables.tf` for full type) |
| `service_annotations` | `map(string)` | `{}` | no | Cloud-specific LB service annotations |
| `nginx_proxy_extra_config` | `any` | `{}` | no | Extra NginxProxy CRD config (e.g. proxy protocol) |

## Outputs

| Name | Description |
|------|-------------|
| `output_attributes` | Module output attributes (base_domain, gateway info, LB DNS) |
| `output_interfaces` | Route x domain cross-product interfaces (sensitive) |
| `domains` | List of all configured domain hostnames |
| `domain` | Base domain hostname (null if disabled) |
| `secure_endpoint` | HTTPS URL for the base domain (null if disabled) |
| `gateway_class` | GatewayClass name |
| `gateway_name` | Gateway resource name |
| `tls_secret` | TLS secret name for the base domain (null if disabled) |
| `load_balancer_hostname` | LB hostname (for CNAME records) |
| `load_balancer_ip` | LB IP address (for A records) |
| `lb_record_value` | DNS record value (hostname or IP) |
| `record_type` | DNS record type (CNAME or A) |
| `cloud_provider` | Detected cloud provider (AWS, GCP, AZURE) |
| `tenant_base_domain` | Tenant base domain from environment |
| `tenant_base_domain_id` | Route53 zone ID (empty if not AWS) |

## What this module creates

- NGINX Gateway Fabric Helm release (chart v2.6.5), with Gateway API experimental
  features enabled (required for the ListenerSet CRD)
- GatewayClass and a Gateway carrying only the HTTP (:80) listener, with
  `allowedListeners` set so ListenerSets can attach
- `ListenerSet` resources holding the per-hostname HTTPS listeners, chunked at 64
  listeners each — this is how the deployment scales past the 64-listeners-per-Gateway
  limit
- HTTPRoute and GRPCRoute resources from spec rules (HTTPS routes attach to the
  ListenerSet listeners; the HTTP listener stays on the Gateway)
- Bootstrap TLS secrets (self-signed) so each HTTPS listener is valid before
  cert-manager issues — the listener-invalid / cert-not-issued deadlock breaker;
  cert-manager overwrites them once HTTP-01 succeeds
- cert-manager ClusterIssuer for HTTP-01 validation, annotated onto the ListenerSet
  so cert-manager's listenerset-shim issues per-hostname certs
- cert-manager Certificate resources (per hostname, apex/concrete names — HTTP-01
  never issues wildcards)
- Basic auth via NGF AuthenticationFilter CRD (optional)
- PodMonitor for Prometheus scraping (optional)
- ReferenceGrant for cross-namespace backends
- ClientSettingsPolicy for body size limits
- Route53 DNS records for base domain and wildcard (AWS only)
- HTTP to HTTPS redirect route (when force_ssl_redirection enabled)

A domain may instead carry a `certificate_reference` (a pre-made TLS secret name) as
an optional escape hatch — that listener uses the supplied secret and cert-manager is
not involved for it.

## What flavor modules provide

| Config | Example (AWS) |
|--------|---------------|
| `service_annotations` | NLB scheme, target type, backend protocol, proxy protocol |
| `nginx_proxy_extra_config` | `rewriteClientIP.mode = "ProxyProtocol"` |
| ACM-at-LB handling | Detect an ACM ARN in `certificate_reference`, set `external_tls_termination` and the NLB `aws-load-balancer-ssl-cert` annotation so the NLB terminates TLS (no in-cluster ACK controller) |
