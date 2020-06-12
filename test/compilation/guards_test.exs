defmodule CainOpenApiTest.Compilation.GuardsTest do
  use ExUnit.Case

  test "compiled guards single is_binary(id)" do
    assert_raise FunctionClauseError, fn ->
      Endpoint.Deployment.get_deployment(nil)
    end
  end

  test "compiled guards single is_map(body)" do
    assert_raise FunctionClauseError, fn ->
      Endpoint.Deployment.create_deployment(nil)
    end
  end

  test "compiled guards single is_list(queries)" do
    assert_raise FunctionClauseError, fn ->
      Endpoint.Deployment.get_deployments(nil)
    end
  end

  test "compiled multiple guards is_binary(id) and is_map(body)" do
    assert_raise FunctionClauseError, fn ->
      Endpoint.Deployment.redeploy(nil, nil)
    end
  end

  test "compiled triple guards is_binary(id) and is_binary(id) and is_map(body)" do
    assert_raise FunctionClauseError, fn ->
     Endpoint.Task.Local.Variable.put_task_local_variable(nil, nil, nil)
    end
  end
end
