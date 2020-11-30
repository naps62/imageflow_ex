defmodule Imageflow.Native do
  use Rustler, otp_app: :imageflow, crate: :imageflow_ex

  def add(_x, _y), do: error()
  def get_long_version_string(), do: error()

  def job_create, do: error()
  def job_destroy(_id), do: error()
  def job_add_input(_id, _io_id, _bytes), do: error()
  def job_get_output(_id), do: error()
  def job_message(_id, _method, _json), do: error()

  def error, do: :erlang.nif_error(:nif_not_loaded)
end
