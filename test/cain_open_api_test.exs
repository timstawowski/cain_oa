defmodule CainOpenApiTest do
  use ExUnit.Case
  # doctest Cain

  setup_all do
    content = File.read!("test/priv/openapi.json") |> Jason.decode!()
    %{open_api_json: content}
  end

  test "module compilation from file", context do
    all_tags_compiled? =
      Enum.all?(
        context.open_api_json["tags"],
        fn %{"name" => tag} ->
          module_from_tag = Module.concat(Endpoint, CainOpenApi.FormatHelper.format_tag(tag))
          Code.ensure_compiled(module_from_tag) == {:module, module_from_tag}
        end
      )

    assert all_tags_compiled? == true
  end

  test "functions compilation from file", context do
    all_functions_compiled? =
      Enum.map(
        context.open_api_json["paths"],
        fn {_path, path_description} ->
          Map.values(path_description)
        end
      )
      |> List.flatten()
      |> Enum.group_by(
        &(Map.get(&1, "tags") |> List.first() |> CainOpenApi.FormatHelper.format_tag()),
        fn elem ->
          func =
            Map.get(elem, "operationId")
            |> Macro.underscore()
            |> String.to_atom()

          arity =
            Map.get(elem, "parameters", %{})
            |> Enum.reduce([], fn %{"in" => type}, acc ->
              cond do
                String.equivalent?(type, "path") -> [type | acc]
                String.equivalent?(type, "query") and !Enum.member?(acc, "query") -> [type | acc]
                true -> acc
              end
            end)
            |> Enum.count()

          body = if elem["requestBody"], do: 1, else: 0

          [{func, arity + body}]
        end
      )
      |> Enum.all?(fn {module, func_list} ->
        module = Module.concat(Endpoint, module)

        Enum.map(func_list, fn [{name, arity}] ->
          function_exported?(module, name, arity)
        end)
      end)

    assert all_functions_compiled? ==
             true
  end
end
