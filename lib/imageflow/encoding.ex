defimpl Jason.Encoder, for: Imageflow.Graph do
  def encode(%{inputs: inputs, outputs: outputs, nodes: nodes, edges: edges}, opts) do
    %{
      io: encode_io(inputs, :in) ++ encode_io(outputs, :out),
      framewise: %{
        graph: %{
          nodes: encode_nodes(nodes),
          edges: encode_edges(edges)
        }
      }
    }
    |> Jason.Encode.map(opts)
  end

  defp encode_io(map, direction) do
    map
    |> Map.keys()
    |> Enum.map(&%{io_id: &1, direction: direction})
  end

  defp encode_nodes(nodes) do
    nodes
  end

  defp encode_edges(edges) do
    edges
    |> Enum.map(fn {from, to} -> %{from: from, to: to, kind: "input"} end)
  end
end
