# ImageflowEx

[imageflow-github]: github.com/imazen/imageflow
[imageflow-json-docs]: https://docs.imageflow.io/json/introduction.html
[my-website]: https://naps62.com

Elixir bindings for [Imageflow][imageflow-github], a safe and blazing fast image workflow library.


## Installation

Add the package to your `mix.exs`:

```elixir
def deps do
  [
    {:imageflow_ex, "~> 0.1.0"}
  ]
end
```

## Usage

### Querying an image

```elixir
alias Imageflow.Job

# create a job
{:ok, job} = Job.create()

# add an input file, with id `0`
:ok = Job.add_input_file(job, 0, "input.jpg")

# you could also add input buffers directly from memory
:ok = Job.add_input_buffer(job, 1, <<0x89, 0x50, 0x4E, 0x47, 0x0D, ... >>)

# call `get_image_info` on buffer with id 0
{:ok, resp} = Job.message("v0.1/get_image_info", %{io_id: 0})

IO.inspect(resp)
%{
  "code" => 200,
  "data" => %{
    "image_info" => %{
      "frame_decodes_into" => "bgr_32",
      "image_height" => 273,
      "image_width" => 185,
      "preferred_extension" => "jpg",
      "preferred_mime_type" => "image/jpeg"
    }
  },
  "message" => "OK",
  "success" => true
}
```

### Transforming an image

```elixir
alias Imageflow.Job

{:ok, job} = Job.create()
:ok = Job.add_input_file(job, 0, "input.jpg")

# allocate an output buffer before manipulating the image
:ok = Job.add_output_buffer(job, 2)


# define a JSON task to transform your image (more details below)
task = %{ ... }

# run
{:ok, response} = Job.message(job, "v0.1/execute", task)

# save the output buffer to a file
:ok = Job.save_output_to_file(job, 1, "output.jpg")
```

### Defining tasks

Imageflow accepts JSON task definitions. Since this package is only a binding to
imageflow, the most reliable documentation on the JSON api available is from the
[here, in the crate docs][imageflow-json-docs]


Here's a simple example, which defines a task that takes buffer `0` as input,
constrains the image to 50px of width, and saves the output to buffer `1`:

```elixir
task = %{
framewise: %{
    steps: [
      # first step is to decode buffer 0
      %{
        decode: %{
          io_id: 0
        }
      },
      # then constrain with to 50px
      %{
        constrain: %{
          mode: "within",
          w: 50
        }
      },
      # and encode current result to buffer 1
      %{
        encode: %{
          io_id: 1,
          preset: %{
            pngquant: %{"quality" => 80}
          }
        }
      }
    ]
  }
}
```

### More complex use cases

As you can probably guess from the API so far, imageflow isn't constrained to
a single input/output per job.
A common use case for web development would be to generate multiple sizes of an
image for a responsive frontend.
More details on details can be found in the [imageflow repo][imageflow-github]

## Contributing

Feel free to contribute. Either by opening an issue, a Pull Request, or contacting the
[team](mailto:mpalhas@gmail.com) directly

If you found a bug, please open an issue. You can also open a PR for bugs or new
features. PRs will be reviewed and subject to our style guide and linters.

# About

This project was developed by [Miguel Palhas][my-website], and is published
under the ISC license.
