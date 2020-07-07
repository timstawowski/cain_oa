defmodule CainOpenApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :cain_oa,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "CainOpenApi",
      source_url: "https://github.com/timstawowski/cain_oa"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:jason, ">= 1.0.0"}
    ]
  end

  defp description do
    "Compile time interpreter of Camunda's OpenAPI specification"
  end

  defp package do
    [
      name: "CainOpenApi",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/timstawowski/cain_oa"}
    ]
  end
end
