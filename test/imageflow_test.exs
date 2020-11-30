defmodule ImageflowTest do
  use ExUnit.Case

  describe "get_long_version_string/0" do
    test "returns the current imageflow version" do
      assert is_binary(Imageflow.get_long_version_string() |> IO.inspect())
    end
  end
end
