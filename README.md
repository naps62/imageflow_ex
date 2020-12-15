# ImageflowEx

[![Github Actions Status](https://github.com/naps62/imageflow_ex/workflows/Test%20Suite/badge.svg)](https://github.com/naps62/imageflow_ex/actions)
[![Hex pm](http://img.shields.io/hexpm/v/imageflow.svg?style=flat)](https://hex.pm/packages/imageflow)

[imageflow-github]: https://github.com/imazen/imageflow
[imageflow-json-docs]: https://docs.imageflow.io/json/introduction.html
[my-website]: https://naps62.com

Elixir bindings for [Imageflow][imageflow-github], a safe and blazing fast image workflow library.

## Installation

Add the package to your `mix.exs`:

```elixir
def deps do
  [
    {:imageflow_ex, "~> 0.2.0"}
  ]
end
```

## Usage

There are two main ways of using `imageflow_ex`:

* [`Imageflow.Graph`](https://hexdocs.pm/imageflow/Imageflow.Graph.html), which is the high-level graph-like API, inspired by [Imageflow.NET](https://github.com/imazen/imageflow-dotnet)
* [`Imageflow.Native`](https://hexdocs.pm/imageflow/Imageflow.Native.html) which provibes lower-level access to Rust binding. Shouldn't be needed unless you need really specific features which aren't yet implemented in the Graph API (but please open an issue so the API can evolve).

Using the Graph API allows you to create processing pipelines to process your
images:


```elixir
alias Imageflow.Graph

Graph.new()
|> Graph.decode_file("input.png")     # read input.png
|> Graph.constrain(200, 200)          # constrain image to 200x200
|> Graph.saturation(0.5)              # set saturation to 0.5 (-1..1 range)
|> Graph.encode_to_file("output.png") # specify output file
|> Graph.run()                        # run the job
```

### Low-level API

This provides direct access to NIF bindings. You probably don't need this,
unless you're relying on APIs that are not yet supported by the Graph API
(please submit an issue).

Check `Imageflow.Native` for documentation and examples.

## Contributing

Feel free to contribute. Either by opening an issue, a Pull Request, or contacting the
[author](mailto:mpalhas@gmail.com) directly

If you found a bug, please open an issue. You can also open a PR for bugs or new
features. PRs will be reviewed and subject to our style guide and linters.

# About

This project was developed by [Miguel Palhas][https://naps62.com], and is published
under the ISC license.
