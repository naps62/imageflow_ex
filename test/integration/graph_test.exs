defmodule Imageflow.Integration.GraphTest do
  use ExUnit.Case

  alias Imageflow.{Graph, Native}

  @input_path "test/fixtures/elixir-logo.jpg"
  @output_path "/tmp/output.png"

  test "can pipe multiple operations" do
    assert :ok =
             Graph.new()
             |> Graph.decode_file(@input_path)
             |> Graph.constrain(20, 20)
             |> Graph.rotate_270()
             |> Graph.transpose()
             |> Graph.color_filter("invert")
             |> Graph.encode_to_file(@output_path)
             |> Graph.run()
  end

  test "can generate multiple images" do
    Graph.new()
    |> Graph.decode_file(@input_path)
    |> Graph.branch(fn graph ->
      graph
      |> Graph.constrain(20, nil)
      |> Graph.encode_to_file("/tmp/20x20.png")
    end)
    |> Graph.branch(fn graph ->
      graph
      |> Graph.constrain(nil, 10)
      |> Graph.encode_to_file("/tmp/10x10.png")
    end)
    |> Graph.run()

    job = Native.create!()
    :ok = Native.add_input_file(job, 0, "/tmp/20x20.png")
    {:ok, resp} = Native.message(job, "v0.1/get_image_info", %{io_id: 0})

    assert get_in(resp, ["data", "image_info", "image_width"]) == 20

    job = Native.create!()
    :ok = Native.add_input_file(job, 0, "/tmp/10x10.png")
    {:ok, resp} = Native.message(job, "v0.1/get_image_info", %{io_id: 0})

    assert get_in(resp, ["data", "image_info", "image_height"]) == 10
  end

  test "can handle multiple operations" do
    assert :ok =
             Graph.new()
             |> Graph.decode_file(@input_path)
             |> Graph.flip_vertical()
             |> Graph.transpose()
             |> Graph.encode_to_file("/tmp/rotated.png")
             |> Graph.run()
  end
end
