defmodule Imageflow do
  @moduledoc """
  There are two main ways of using `imageflow_ex`:

  * `Imageflow.Graph`, which is the high-level graph-like API, inspired by [Imageflow.NET](https://github.com/imazen/imageflow-dotnet]
  * `Imageflow.Native` which provibes lower-level access to Rust binding. Shouldn't be needed unless you need really specific features which aren't yet implemented in the Graph API (but please open an issue so the API can evolve).
  """

  @doc """
  Returns the version string of the current imageflow Rust crate being used
  """
  def get_long_version_string, do: Imageflow.NIF.get_long_version_string()
end
