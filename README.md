# Owlery

Owlery is a backend application used to relay messages between various frontends
connected to it. It was build for the [Cluegrid]() crossword app. It is built
using elixir and cowboy.

## Basic Architecture

We use GenServer for every `Channel`. It maintains the state of the game, as
well as managing the communication between all connected clients.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `owlery` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:owlery, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/owlery](https://hexdocs.pm/owlery).

