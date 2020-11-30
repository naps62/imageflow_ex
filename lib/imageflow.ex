defmodule Imageflow do
  alias Imageflow.{Native, Job}

  def get_long_version_string, do: Native.get_long_version_string()
end
