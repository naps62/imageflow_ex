defmodule Imageflow.GraphRunner do
  alias Imageflow.{Graph, Native}

  def run(%Graph{} = graph) do
    with {:ok, job} <- Native.create(),
         :ok <- add_inputs(job, graph.inputs),
         :ok <- add_outputs(job, graph.outputs),
         :ok <- send_task(job, graph),
         :ok <- save_outputs(job, graph.outputs),
         {:ok, results} <- print_results(job, graph.outputs) do
      if results == [], do: :ok, else: {:ok, results}
    end
  end

  defp add_inputs(job, inputs) do
    inputs
    |> Enum.reduce_while(:ok, fn
      {id, value}, :ok ->
        case value do
          {:file, path} -> Native.add_input_file(job, id, path)
          {:bytes, blob} -> Native.add_input_buffer(job, id, blob)
        end
        |> case do
          :ok -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
    end)
  end

  defp add_outputs(job, inputs) do
    inputs
    |> Enum.reduce_while(:ok, fn
      {id, value}, :ok ->
        case value do
          {:file, _path} -> Native.add_output_buffer(job, id)
          :bytes -> Native.add_output_buffer(job, id)
        end
        |> case do
          :ok -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
    end)
  end

  defp save_outputs(job, outputs) do
    outputs
    |> Enum.reduce_while(:ok, fn
      {id, value}, :ok ->
        case value do
          {:file, path} -> Native.save_output_to_file(job, id, path)
          :bytes -> :ok # skip
        end
        |> case do
          :ok -> {:cont, :ok}
          {:error, _} = error -> {:halt, error}
        end
    end)
  end

  def print_results(job, outputs) do
    outputs
    |> Enum.reduce_while({:ok, []}, fn ({id, value}, {:ok, acc}) ->
      case value do
        :bytes -> Native.get_output_buffer(job, id)
        {:file, _} -> :skip # skip
      end
      |> case do
        :skip -> {:cont, {:ok, acc}}
        {:ok, results} -> {:cont, {:ok, :binary.list_to_bin(results)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp send_task(job, graph) do
    with {:ok, _response} <- Native.message(job, "v0.1/execute", graph) do
      :ok
    end
  end
end
