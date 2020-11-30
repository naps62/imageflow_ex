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
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, github: "hansihe/rustler", sparse: "rustler_mix"},
      {:jason, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
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
