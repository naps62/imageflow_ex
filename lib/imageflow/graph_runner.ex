defmodule Imageflow.GraphRunner do
  alias Imageflow.{Graph, Native, Result}

  def run(%Graph{} = graph) do
    with {:ok, job} <- Native.create(),
         :ok <- add_inputs(job, graph.inputs),
         :ok <- add_outputs(job, graph.outputs),
         :ok <- send_task(job, graph),
         :ok <- save_outputs(job, graph.outputs) do
      {:ok, job, graph}
    end
  end

  def get_results(job, %Graph{outputs: outputs} = graph) do
    outputs
    |> Enum.reduce_while({:ok, []}, fn {id, value}, {:ok, _acc} ->
      case value do
        :bytes ->
          case Native.get_output_buffer(job, id) do
            {:ok, results} -> {:cont, {:ok, :binary.list_to_bin(results)}}
            {:error, _} = error -> {:halt, error}
          end

        {:file, path} ->
          {:cont, {:ok, path}}
      end
    end)
    |> case do
      {:ok, results} ->
        {:ok, %Result{job: job, graph: graph, output: results}}

      error ->
        error
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
      {id, _}, :ok ->
        with :ok <- Native.add_output_buffer(job, id) do
          {:cont, :ok}
        else
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
          # skip
          :bytes -> :ok
        end
        |> case do
          :ok -> {:cont, :ok}
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
