# CainOpenApi

Camunda-BPM 7.13.0 is shipped with a REST-API considering the OpenAPI specification 3.0.2. so the specs can be interpreted during compile time.  

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cain_oa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cain_oa, "~> 0.1.0"}
  ]
end
```

## Using

Download the current open api spec following the instructions on the official Camunda docs web-page (https://docs.camunda.org/manual/latest/reference/rest/openapi/).

Define a module which is using CainOpenApi.

```elixir
defmodule MyApp.Endpoint do
  use CainOpenApi
end
```

After compilation the REST-Endpoints are accessible like `Endpoint.Deployment` and returning a four elmented tuple including all relevant  information `method`, `path`, `body` and `query` for your HTTP-Client.

```elixir
Endpoint.Deployment.get_deployments()
#  {:get, "/deployment", %{}, []}
```

An Endpoint.Module is equiped with all possible functions and parameters.

```elixir
iex(1)> Endpoint.Deployment.get_deployment
get_deployment/1                  get_deployment_resource/2         
get_deployment_resource_data/2    get_deployment_resources/1        
get_deployments/0                 get_deployments/1                 
get_deployments_count/0           get_deployments_count/1   
```

Just call `IEx.Helpers.h` for the offical REST-docs of a function.

Additionaly, every compiled module is equiped with an `.__queries__/1` or
`.__request_body__/1` function to ask for usable params by simply invoking them using a function name as an atom.

```elixir
iex(1)> Endpoint.Deployment.__queries__(:get_deployments)
[
  id: :string,
  name: :string,
  name_like: :string,
  source: :string,
  without_source: :boolean,
  tenant_id_in: :string,
  without_tenant_id: :boolean,
  include_deployments_without_tenant_id: :boolean,
  after: :string,
  before: :string,
  sort_by: :string,
  sort_order: :string,
  first_result: :integer,
  max_results: :integer
]
```
