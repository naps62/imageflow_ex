defmodule Imageflow do
  alias Imageflow.{Native, Job}

  def get_long_version_string(), do: Native.get_long_version_string()

  @input "input.jpg"
  @output "output.jpg"

  @steps %{
    framewise: %{
      steps: [
        %{
          decode: %{
            io_id: 0
          }
        },
        %{
          constrain: %{
            mode: "within",
            w: 50
          }
        },
        %{
          encode: %{
            io_id: 1,
            preset: %{
              pngquant: %{quality: 80}
            }
          }
        }
      ]
    }
  }

  def test do
    {:ok, job} = Job.create()

    job
    |> Job.add_input_file(0, @input)
    |> Job.add_output_buffer(1)
    |> Job.message("v0.1/execute", @steps)
    |> Job.save_output_to_file(1, @output)

    Job.destroy(job)
  end
end
