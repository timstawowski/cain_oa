defmodule CainOpenApiTest.CompiledModule.DeploymentTest do
  use ExUnit.Case

  alias Endpoint.Deployment, as: D
  # create_deployment/1               delete_deployment/1
  # delete_deployment/2               get_deployment/1
  # get_deployment_resource/2         get_deployment_resource_data/2
  # get_deployment_resources/1        get_deployments/0
  # get_deployments/1                 get_deployments_count/0
  # get_deployments_count/1           redeploy/2

  test "create_deployment/1" do
    assert D.create_deployment(%{}) == {:post, "/deployment/create", %{}, []}
  end
end
