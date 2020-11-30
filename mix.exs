defmodule Imageflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :imageflow,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      rustler_crates: rustler_crates(),
      deps: deps()
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
      {:rustler, "~> 0.21.0"},
      {:jason, "~> 1.2"}
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
end
