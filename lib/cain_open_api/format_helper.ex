defmodule CainOpenApi.FormatHelper do
  @moduledoc false
  defmodule InvalidFormat, do: defexception(message: "Invalid open api format")

  @valid_schema_keys ["components", "externalDocs", "info", "openapi", "paths", "servers", "tags"]

  defmodule BluePrint do
    defstruct [
      :module,
      :method,
      :endpoint,
      :function,
      :description,
      body: %{},
      query: [],
      path: []
    ]
  end

  def build_blueprint(decoded_content) do
    decoded_content
    |> Map.keys()
    |> Enum.all?(&(validate_schema_keys(&1) == true))
    |> if do
      {:ok, format_decoded_content(decoded_content)}
    else
      raise InvalidFormat
    end
  end

  defp validate_schema_keys(keys) when keys in @valid_schema_keys, do: true

  defp validate_schema_keys(_keys), do: false

  def format_decoded_content(%{"paths" => paths}) do
    Enum.map(paths, fn {path, endpoint_description} ->
      Enum.map(endpoint_description, fn {method, de} ->
        params = format_params(de["parameters"])
        description = format_description(de["description"])

        request_body =
          if de["requestBody"] do
            create_request_body(de["requestBody"]["content"])
          end

        Map.put(de, "method", method)
        |> Map.put("endpoint", path)
        |> Map.put("operationId", eval_func_name_from_path_item_object(de))
        |> Map.put("description", description)
        |> Map.put("requestBody", request_body)
        |> Map.merge(params)
      end)
    end)
    |> List.flatten()
    |> Enum.group_by(&(Map.get(&1, "tags") |> List.first()), fn map ->
      Map.delete(map, "tags")
      |> Map.delete("parameters")
      # TODO: use response information
      # |> Map.delete("responses")
    end)
    |> Enum.reduce(%{}, fn {tag, cont}, acc ->
      Map.put(acc, format_tag(tag), cont)
    end)
  end

  def format_params(nil), do: %{}

  def format_params(params) do
    Enum.group_by(params, &Map.get(&1, "in"), fn attr ->
      name = attr["name"]
      type = attr["schema"]["type"]
      {transform(name), transform(type)}
    end)
  end

  def format_description(nil), do: %{}

  def format_description(description),
    do: String.replace(description, ~r/([a-z]+?)([A-Z])/, &Macro.underscore(&1))

  def endpoint(str, mod) do
    chunks = String.split(str, ["{", "}"], trim: true)

    if Enum.count(chunks) > 1 do
      args =
        Enum.map(chunks, fn chunk ->
          if !String.contains?(chunk, "/") do
            identifier = transform(chunk)

            {:"::", [],
             [
               {{:., [], [Kernel, :to_string]}, [], [{identifier, [], mod}]},
               {:binary, [], mod}
             ]}
          else
            chunk
          end
        end)

      {:<<>>, [], args}
    else
      str
    end
  end

  def eval_func_name_from_path_item_object(%{"operationId" => func_name}),
    do: transform(func_name)

  def transform(term), do: Macro.underscore(term) |> String.to_atom()

  def format_tag(tag) do
    if String.contains?(tag, "Task ") do
      String.replace(tag, " ", ".")
    else
      String.replace(tag, " ", "")
    end
  end

  def type_from_spec(%{"type" => type}), do: transform(type)

  def create_request_body(content) do
    [content_type] = Map.keys(content)
    schema_ref = content[content_type]["schema"]["$ref"] |> schema_ref()

    %{"content_type" => content_type, "schema" => schema_ref}
  end

  def schema_ref(schema_ref) when is_binary(schema_ref) do
    schema_ref
    |> String.split("/")
    |> List.last()
  end
end
