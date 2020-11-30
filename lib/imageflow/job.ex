defmodule Imageflow.Job do
  alias Imageflow.Native

  @type t :: %__MODULE__{}
  @type native_ret_t :: :ok | {:error, binary}

  defstruct id: nil

  @spec create :: {:ok, t}
  def create do
    {:ok, id} = Native.job_create()

    {:ok, %__MODULE__{id: id}}
  end

  @spec create! :: t
  def create! do
    {:ok, job} = __MODULE__.create()

    job
  end

  def destroy(%__MODULE__{id: id}), do: Native.job_destroy(id)

  @spec add_input_buffer(t, number, binary) :: native_ret_t
  def add_input_buffer(%__MODULE__{id: id}, io_id, bytes) do
    Native.job_add_input_buffer(id, io_id, bytes)
  end

  @spec add_input_file(t, number, binary) :: native_ret_t
  def add_input_file(%__MODULE__{id: id}, io_id, path) do
    Native.job_add_input_file(id, io_id, path)
  end

  @spec add_output_buffer(t, number) :: native_ret_t
  def add_output_buffer(%__MODULE__{id: id}, io_id) do
    Native.job_add_output_buffer(id, io_id)
  end

  @spec save_output_to_file(t, number, binary) :: native_ret_t
  def save_output_to_file(%__MODULE__{id: id}, io_id, path) do
    Native.job_save_output_to_file(id, io_id, path)
  end

  @spec get_output_buffer(t, number) :: {:ok, binary} | {:error, binary}
  def get_output_buffer(%__MODULE__{id: id} = _job, io_id) do
    Native.job_get_output_buffer(id, io_id)
  end

  @spec message(t, binary, binary) :: {:ok, any} | {:error, binary}
  def message(%__MODULE__{id: id}, method, message) do
    with {:ok, resp} <- Native.job_message(id, method, Jason.encode!(message)) do
      {:ok, Jason.decode!(resp)}
    end
  end
end
