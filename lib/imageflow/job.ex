defmodule Imageflow.Job do
  alias Imageflow.Native

  defstruct [:id]

  def create do
    {:ok, id} = Native.job_create()

    {:ok, %__MODULE__{id: id}}
  end

  def destroy(%__MODULE__{id: id}), do: Native.job_destroy(id)

  def add_input(%__MODULE__{id: id}, io_id, bytes) do
    Native.job_add_input(id, io_id, bytes)
  end

  def message(%__MODULE__{id: id}, method, message) do
    with {:ok, resp} <- Native.job_message(id, method, Jason.encode!(message)) do
      Jason.decode(resp)
    end
  end
end
