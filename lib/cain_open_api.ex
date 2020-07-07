defmodule CainOpenApi do
  @moduledoc false
  defmodule FileNotFound, do: defexception([:message])

  defmacro __using__(_opts) do
    file_path = Application.app_dir(:cain_oa, "priv/openapi.json")

    with {:ok, content} <- File.read(file_path),
         {:ok, decoded_content} <- Jason.decode(content),
         {:ok, blueprint} <- CainOpenApi.FormatHelper.build_blueprint(decoded_content) do
      for {tag, description} <- blueprint do
        deployment_mod = Module.concat(__CALLER__.module, tag)

        {:defmodule, context, [taged_mod, _do]} =
          quote do
            defmodule unquote(deployment_mod) do
              @moduledoc false
            end
          end

        new =
          Enum.map(description, fn content ->
            doc = content["description"]
            method = String.to_atom(content["method"])

            endpoint = CainOpenApi.FormatHelper.endpoint(content["endpoint"], deployment_mod)

            func_name = content["operationId"]

            ## ARGS ##
            paths = CainOpenApi.create_path(content["path"], deployment_mod)
            queries = content["query"] || []
            request_body = content["requestBody"]

            args_with_request = CainOpenApi.add_request_body(request_body, paths, deployment_mod)

            args = CainOpenApi.add_queries(queries, args_with_request, deployment_mod)

            query_elem =
              if Enum.count(queries) > 1 do
                Macro.var(:queries, deployment_mod)
              else
                []
              end

            body_elem =
              if content["requestBody"] do
                Macro.var(:body, deployment_mod)
              else
                Macro.escape(%{})
              end

            query_func =
              quote do
                def __queries__(unquote(func_name)) do
                  unquote(queries)
                end
              end

            request_func =
              quote do
                def __request_body__(unquote(func_name)) do
                  unquote(Macro.escape(request_body))
                end
              end

            func_func =
              quote do
                @doc unquote(doc)
                def unquote(func_name)(unquote_splicing(args)) do
                  {unquote(method), unquote(endpoint), unquote(body_elem), unquote(query_elem)}
                end
              end
              |> add_guards()

            quote do
              unquote(query_func)
              unquote(request_func)
              unquote(func_func)
            end
          end)
          |> List.flatten()

        {:defmodule, context, [taged_mod, [do: new]]}
      end
    else
      {:error, _} ->
        raise CainOpenApi.FileNotFound, message: "No such file on the given path!"
    end
  end

  def add_guards({:__block__, [], func_defition} = do_block_definition) do
    [
      doc_ast,
      {:def, [{:context, context}, imp], [{_func_name, _func_context, args} = func, do_block]}
    ] = func_defition

    if !Enum.empty?(args) do
      guard_result =
        Enum.reduce(args, [func], fn {arg_type, _meta, context_mod} = arg, acc ->
          if Enum.count(acc) < 2 do
            elem = build_guard(arg_type, context_mod, arg)

            acc ++ [elem]
          else
            [func_def, guard] = acc

            elem = build_guard(arg_type, context_mod, arg)
            context = Keyword.merge(elem(func_def, 1), [{:import, Kernel}])

            [func, {:and, context, [guard] ++ [elem]}]
          end
        end)

      args = {:when, [context: context], guard_result}
      {:__block__, [], [doc_ast, {:def, [{:context, context}, imp], [args, do_block]}]}
    else
      do_block_definition
    end
  end

  def build_guard(arg_type, context_mod, arg) do
    case arg_type do
      :\\ ->
        context = List.first(context_mod) |> elem(2)

        {:is_list, [{:context, context}, {:import, Kernel}], [List.first(context_mod)]}

      :body ->
        {:is_map, [{:context, context_mod}, {:import, Kernel}], [arg]}

      _string ->
        {:is_binary, [{:context, context_mod}, {:import, Kernel}], [arg]}
    end
  end

  def add_request_body(request_body, args, mod) do
    if request_body do
      args ++ [Macro.var(:body, mod)]
    else
      args
    end
  end

  def add_queries(queries, args, mod) do
    if !Enum.empty?(queries) do
      args ++ [{:\\, [], [Macro.var(:queries, mod), []]}]
    else
      args
    end
  end

  def create_path(nil, _mod) do
    []
  end

  def create_path(path_params, mod) do
    Enum.map(path_params, fn {p, _string} ->
      Macro.var(p, mod)
    end)
  end
end
