defmodule Imageflow.JobTest do
  use ExUnit.Case

  alias Imageflow.Job

  describe "create/0" do
    test "creates a job" do
      job = Job.create()

      assert {:ok, %Job{}} = job
    end
  end

  describe "create!/0" do
    test "creates a job" do
      job = Job.create!()

      assert %Job{} = job
    end
  end

  describe "destroy/1" do
    test "can destroy existing jobs" do
      job = Job.create!()

      assert :ok = Job.destroy(job)
    end
  end

  describe "image processing from memory buffers" do
    @img <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48,
           0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00,
           0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78,
           0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
           0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

    test "allows input bytes to be added and image width queried" do
      job = Job.create!()

      assert :ok = Job.add_input_buffer(job, 0, @img)
      assert {:ok, resp} = Job.message(job, "v0.1/get_image_info", %{io_id: 0})
      assert get_in(resp, ["success"]) == true
      assert get_in(resp, ["code"]) == 200
      assert get_in(resp, ["data", "image_info", "image_width"]) == 1
    end

    test "allows image to be upscaled" do
      job = Job.create!()

      assert :ok = Job.add_input_buffer(job, 0, @img)
      assert :ok = Job.add_output_buffer(job, 1)

      task = %{
        "framewise" => %{
          "steps" => [
            %{
              "command_string" => %{
                "kind" => "ir4",
                "value" => "width=100&height=100&scale=both&format=jpg",
                "decode" => 0,
                "encode" => 1
              }
            }
          ]
        }
      }

      assert {:ok, resp} = Job.message(job, "v0.1/execute", task)

      assert %{
               "success" => true,
               "code" => 200,
               "data" => %{
                 "job_result" => %{
                   "encodes" => [
                     %{"w" => 100, "h" => 100}
                   ]
                 }
               }
             } = resp

      assert {:ok, bytes} = Job.get_output_buffer(job, 1)
      assert [0xFF, 0xD8, 0xFF | _] = bytes
    end
  end

  describe "image processing from files" do
    @img_path "test/fixtures/elixir-logo.jpg"

    test "allows input file to be added and image size queried" do
      job = Job.create!()

      :ok = Job.add_input_file(job, 0, @img_path)
      {:ok, resp} = Job.message(job, "v0.1/get_image_info", %{io_id: 0})

      assert get_in(resp, ["success"]) == true
      assert get_in(resp, ["code"]) == 200
      assert get_in(resp, ["data", "image_info", "image_width"]) == 185
      assert get_in(resp, ["data", "image_info", "image_height"]) == 273
    end

    test "allows image file to be downscaled and save to new file" do
      job = Job.create!()

      :ok = Job.add_input_file(job, 0, @img_path)
      :ok = Job.add_output_buffer(job, 1)

      task = %{
        "framewise" => %{
          "steps" => [
            %{
              "decode" => %{
                "io_id" => 0
              }
            },
            %{
              "constrain" => %{
                "mode" => "within",
                "w" => 50
              }
            },
            %{
              "encode" => %{
                "io_id" => 1,
                "preset" => %{
                  "pngquant" => %{"quality" => 80}
                }
              }
            }
          ]
        }
      }

      {:ok, %{"success" => true}} = Job.message(job, "v0.1/execute", task)
      :ok = Job.save_output_to_file(job, 1, "/tmp/output.png")

      job2 = Job.create!()
      :ok = Job.add_input_file(job2, 0, "/tmp/output.png")
      {:ok, resp} = Job.message(job2, "v0.1/get_image_info", %{io_id: 0})

      assert get_in(resp, ["data", "image_info", "image_width"]) == 50
    end
  end
end
