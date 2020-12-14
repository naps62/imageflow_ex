defmodule Imageflow.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :imageflow,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      rustler_crates: rustler_crates(),
      deps: deps(),
      compilers: [:rustler] ++ Mix.compilers(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:rustler, "~> 0.21.1"},
      {:jason, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp rustler_crates do
    [
      imageflow_ex: [
        path: "native/imageflow_ex",
        mode: rustc_mode(Mix.env())
      ]
    ]
  end

  defp rustc_mode(:prod), do: :release
  defp rustc_mode(_), do: :debug

  defp description do
    "Elixir bindings for imageflow"
  end

  defp package do
    [
      maintainers: ["Miguel Palhas"],
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/naps62/imageflow_ex"},
      files: ~w(.formatter.exs mix.exs README.md lib native LICENSE)
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: "https://github.com/naps62/imageflow_ex",
      source_ref: "v#{@version}"
    ]
  end
end
