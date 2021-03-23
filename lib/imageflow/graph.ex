defmodule Imageflow.Graph do
  @moduledoc """
  With the Graph API, you can specify a task to process multiple inputs/outputs
  according to a pipeline of operations.

  For example:

  alias Imageflow.Graph

      Graph.new()
      |> Graph.decode_file("input.png")     # read input.png
      |> Graph.constrain(200, 200)          # constrain image to 200x200
      |> Graph.saturation(0.5)              # set saturation to 0.5 (-1..1 range)
      |> Graph.encode_to_file("output.png") # specify output file
      |> Graph.run()                        # run the job ```

  Within a `Graph`, you specify all the operations, inputs and outputs you
  need. Only when `Graph.run/1` is called is this actually executed

  You can also specify multiple outputs, which is a common use-case. For
  example, for web/mobile development, you may want to generate multiple images
  with different resolutions for responsive apps:

      alias Imageflow.Graph

      Graph.new()
      |> Graph.decode_file(@input_path)
      |> Graph.branch(fn graph ->
        # 2160px wide image for retina displays graph
        graph
        |> Graph.constrain(2160, nil)
        |> Graph.encode_to_file("desktop@2x.png")
      end)
      |> Graph.branch(fn graph ->   # 1080px wide image for desktop
        graph
        |> Graph.constrain(1080, nil)
        |> Graph.encode_to_file("desktop.png")
      end)
      |> Graph.branch(fn graph ->   # 720px wide image for tablet
        graph
        |> Graph.constrain(720, nil)
        |> Graph.encode_to_file("tablet.png")
      end)
      |> Graph.branch(fn graph ->   # 600px wide image for mobile
        graph
        |> Graph.constrain(600, nil)
        |> Graph.encode_to_file("mobile.png")
      end)
      |> Graph.run()

  The above snippet will generate 4 images, all processed under the same
  `imageflow` job.

  Check the documentation to see what other operations are available

  You may also want to check the base repo for [`imageflow`](https://github.com/imazen/imageflow), or its live [JSON API documentation](https://docs.imageflow.io/json/introduction.html)
  """

  alias Imageflow.GraphRunner

  defstruct inputs: %{}, outputs: %{}, nodes: %{}, edges: [], node_count: 0, io_count: 0, tip: 0

  @type t :: %__MODULE__{
          inputs: map(),
          outputs: map(),
          nodes: map(),
          node_count: integer(),
          io_count: integer(),
          tip: integer()
        }
  @type point_t :: {number, number}

  @doc """
  Creates a new graph instance
  """
  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Appends a new input file to be decoded
  """
  @spec decode_file(t, binary) :: t
  def decode_file(%{io_count: io_count} = graph, path) do
    io_id = io_count + 1

    graph
    |> add_input(io_id, {:file, path})
    |> append_node(%{decode: %{io_id: io_id}})
  end

  @doc """
  Appends a string to be decoded
  """
  @spec decode_string(t, binary) :: t
  def decode_string(%{io_count: io_count} = graph, string) do
    io_id = io_count + 1

    graph
    |> add_input(io_id, {:bytes, string})
    |> append_node(%{decode: %{io_id: io_id}})
  end

  @doc """
  Specifies a destination file for the current branch of the pipeline

  No further processing operations should be appended at the current branch after this call.

  The last two arguments specify the encoder and optional encoding parameters.

  The following parameters are valid encoders:
  * `:jpg`: Alias to `:mozjpeg`
  * `:jpeg`: Alias to `:mozjpeg`
  * `:png`: Alias to `:lodepng`
  * `:webp: Alias to `:webplossless
  * `:mozjpeg`
  * `:gif`
  * `:lodepng`: Lossless PNG
  * `:pngquant`: Lossy PNG
  * `:webplossy`: Lossy WebP
  * `:webplossless`: Lossless WebP

  Check the official [encoding documentation](https://docs.imageflow.io/json/encode.html) to see the parameters available to each encoder
  """
  @spec encode_to_file(t, binary, binary | atom, map) :: t
  def encode_to_file(graph, path, encoder \\ :png, opts \\ %{}) do
    add_encode_node(graph, {:file, path}, encoder, opts)
  end

  @doc """
  Returns the converted image as a string.

  No further processing operations should be appended at the current branch after this call.

  The last two arguments specify the encoder and optional encoding parameters.

  The following parameters are valid encoders:
  * `:jpg`: Alias to `:mozjpeg`
  * `:jpeg`: Alias to `:mozjpeg`
  * `:png`: Alias to `:lodepng`
  * `:webp: Alias to `:webplossless
  * `:mozjpeg`
  * `:gif`
  * `:lodepng`: Lossless PNG
  * `:pngquant`: Lossy PNG
  * `:webplossy`: Lossy WebP
  * `:webplossless`: Lossless WebP

  Check the official [encoding documentation](https://docs.imageflow.io/json/encode.html) to see the parameters available to each encoder
  """

  @spec encode_to_string(t, binary | atom, map) :: t
  def encode_to_string(graph, encoder \\ :png, opts \\ %{}) do
    add_encode_node(graph, :bytes, encoder, opts)
  end

  defp add_encode_node(%{io_count: io_count} = graph, output_type, encoder, opts) do
    io_id = io_count + 1

    graph
    |> add_output(io_id, output_type)
    |> append_node(%{encode: %{io_id: io_id, preset: preset_for(encoder, opts)}})
  end

  @doc """
  Creates a new branch, allowing you do add multiple paths and outputs to the
  graph

  If you need to output multiple formats, this is what you should use. Perform
  all common operations first, then call a branch with each specialized part
  and its corresponding output
  """
  @spec branch(t, (t -> t)) :: t
  def branch(%{tip: tip} = graph, fun) do
    fun.(graph)
    |> Map.put(:tip, tip)
  end

  @doc """
  Constrains image dimensions. By default, it uses the "within" constraint mode
  from imageflow, but that can be overriden:

      Graph.constrain(graph, 800, 600, %{mode: "fit", gravity: %{percentage:
      %{x: 50, y: 50}}

  Check the [JSON API docs for the constrain
  operation](https://docs.imageflow.io/json/constrain.html) for more info on
  all options available
  """
  @spec constrain(t, number | nil, number | nil, map) :: t
  def constrain(graph, w, h, opts \\ %{}) do
    graph
    |> append_node(%{constrain: %{mode: "within", w: w, h: h} |> Map.merge(opts)})
  end

  @doc """
  Like a crop command, but you can specify coordinates outside of the
  image and thereby add padding. It's like a window.
  """
  @spec region(t, number, number, number, number, binary) :: t
  def region(graph, x1, y1, x2, y2, bg_color \\ "transparent") do
    graph
    |> append_node(%{
      region: %{x1: x1, y1: y1, x2: x2, y2: y2, background_color: bg_color}
    })
  end

  @spec region_percent(t, number, number, number, number, binary) :: t
  def region_percent(graph, x1, y1, x2, y2, bg_color \\ "transparent") do
    graph
    |> append_node(%{
      region_percent: %{x1: x1, y1: y1, x2: x2, y2: y2, background_color: bg_color}
    })
  end

  @spec crop_whitespace(t, number, number) :: t
  def crop_whitespace(graph, threshold, percent_padding) do
    graph
    |> append_node(%{
      crop_whitespace: %{threshold: threshold, percent_padding: percent_padding}
    })
  end

  @doc """
  Flips the image horizontally
  """
  @spec flip_horizontal(t) :: t
  def flip_horizontal(graph), do: append_node(graph, :flip_h)

  @doc """
  Flips the image vertically
  """
  @spec flip_vertical(t) :: t
  def flip_vertical(graph), do: append_node(graph, :flip_v)

  @doc """
  Transposes the image
  """
  @spec transpose(t) :: t
  def transpose(graph), do: append_node(graph, :transpose)

  @doc """
  Rotates image 90 degrees
  """
  @spec rotate_90(t) :: t
  def rotate_90(graph), do: append_node(graph, :rotate_90)

  @doc """
  Rotates image 180 degrees
  """
  @spec rotate_180(t) :: t
  def rotate_180(graph), do: append_node(graph, :rotate_180)

  @doc """
  Rotates image 270 degrees
  """
  @spec rotate_270(t) :: t
  def rotate_270(graph), do: append_node(graph, :rotate_270)

  @doc """
  Draws a of the given color int he given coordinates
  """
  @spec fill_rect(t, number, number, number, number, binary) :: t
  def fill_rect(graph, x1, y1, x2, y2, color \\ "black") do
    graph
    |> append_node(%{fill_rect: %{x1: x1, y1: y1, x2: x2, y2: y2, color: color}})
  end

  @doc """
  Resizes the canvas according to the given amounts for each direction, filling
  in the empty space with the given HEX color
  """
  @spec expand_canvas(t, number, number, number, number, binary) :: t
  def expand_canvas(graph, left, top, right, bottom, color_hex \\ "FFFFFF00") do
    graph
    |> append_node(%{
      expand_canvas: %{
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        color: %{srgb: %{hex: color_hex}}
      }
    })
  end

  @doc """
  Adjusts the alpha channel of the image, from 0 (transparent) to 1 (opaque)
  """
  @spec transparency(t, number) :: t
  def transparency(graph, opacity) do
    graph
    |> append_node(%{color_filter_srgb: %{alpha: opacity}})
  end

  @doc """
  Adjusts contrast betweeen -1 and 1
  """
  @spec contrast(t, number) :: t
  def contrast(graph, amount) do
    graph
    |> append_node(%{color_filter_srgb: %{contrast: amount}})
  end

  @doc """
  Adjusts brightness betweeen -1 and 1
  """
  @spec brightness(t, number) :: t
  def brightness(graph, amount) do
    graph
    |> append_node(%{color_filter_srgb: %{brightness: amount}})
  end

  @doc """
  Adjusts saturation betweeen -1 and 1
  """
  @spec saturation(t, number) :: t
  def saturation(graph, amount) do
    graph
    |> append_node(%{color_filter_srgb: %{saturation: amount}})
  end

  @doc """
  Applies a color filter to the image. All filters will operate on the sRGB
  color space, so may not provide ideal results.

  Check the [JSON API
  documentation](https://docs.imageflow.io/json/color_filter_srgb.html) for
  available filters.
  """
  @spec color_filter(t, number) :: t
  def color_filter(graph, filter) do
    graph
    |> append_node(%{color_filter_srgb: filter})
  end

  defp append_node(
         %{edges: edges, nodes: nodes, tip: tip, node_count: node_count} = graph,
         node
       ) do
    node_id = node_count + 1
    nodes = Map.put(nodes, node_id, node)

    edges =
      case tip do
        0 -> edges
        tip -> [{tip, node_id} | edges]
      end

    %{graph | nodes: nodes, edges: edges, tip: node_id, node_count: node_count + 1}
  end

  def run(graph) do
    GraphRunner.run(graph)
  end

  def get_results(job, graph), do: GraphRunner.get_results(job, graph)

  defp add_input(%{io_count: io_count, inputs: inputs} = graph, io_id, value) do
    %{graph | io_count: io_count + 1, inputs: Map.put(inputs, io_id, value)}
  end

  defp add_output(%{io_count: io_count, outputs: outputs} = graph, io_id, value) do
    %{graph | io_count: io_count + 1, outputs: Map.put(outputs, io_id, value)}
  end

  defp preset_for(encoder, opts) do
    encoder
    |> to_string()
    |> case do
      jpeg when jpeg in ~w(jpeg jpg mozjpeg) ->
        {:mozjpeg, %{quality: 90, progressive: false}}

      png when png in ~w(png lodepng) ->
        {:lodepng, %{maximum_deflate: false}}

      "gif" ->
        :gif

      "webp" ->
        :webplossless

      "lossy_png" ->
        {:pngquant, %{quality: 90, minimum_quality: 20, speed: nil, maximum_deflate: nil}}

      "lossy_webp" ->
        {:webplossy, %{quality: 80}}
    end
    |> case do
      {encoder, defaults} -> %{encoder => Map.merge(defaults, opts)}
      encoder when is_atom(encoder) -> encoder
    end
  end
end
