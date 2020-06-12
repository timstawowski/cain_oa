defmodule Endpoint do
  use CainOpenApi,
      "priv/openapi.json"
end

ExUnit.start()
