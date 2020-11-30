defmodule Imageflow.Job do
  alias Imageflow.Native

  defstruct [:id]

  def create do
    {:ok, id} = Native.job_create()

    {:ok, %__MODULE__{id: id}}
  end

  def destroy(%__MODULE__{id: id}), do: Native.job_destroy(id)

  def add_input_buffer(%__MODULE__{id: id} = job, io_id, bytes) do
    Native.job_add_input_buffer(id, io_id, bytes)

    job
  end

  def add_input_file(%__MODULE__{id: id} = job, io_id, path) do
    Native.job_add_input_file(id, io_id, path)

    job
  end

  def add_output_buffer(%__MODULE__{id: id} = job, io_id) do
    Native.job_add_output_buffer(id, io_id)

    job
  end

  def get_output_buffer(%__MODULE__{id: id} = job, io_id) do
    Native.job_get_output_buffer(id, io_id)

    job
  end

  def save_output_to_file(%__MODULE__{id: id} = job, io_id, path) do
    Native.job_save_output_to_file(id, io_id, path)

    job
  end

  def message(%__MODULE__{id: id} = job, method, message) do
    with {:ok, resp} <- Native.job_message(id, method, Jason.encode!(message)) do
      Jason.decode(resp)
    end

    job
  end
end
