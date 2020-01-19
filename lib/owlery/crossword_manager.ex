defmodule Owlery.CrosswordManager do
  require Logger

  def get_latest_crosswords() do
    data_directory = Application.fetch_env!(:owlery, :crossword_data_directory)
    endpoint = Application.fetch_env!(:owlery, :crossword_data_endpoint)
    {:ok, puzzles} = File.ls(data_directory)

    titles =
      puzzles
      |> Enum.map(fn file -> data_directory <> file end)
      |> Enum.map(fn file -> CrosswordDataReader.start_link(file) end)

    links =
      puzzles
      |> Enum.map(fn str -> endpoint <> str end)

    titles
    |> Enum.zip(links)
    |> Enum.map(fn {title, link} -> %{:title => title, :link => link} end)
    |> Enum.sort()
  end
end

defmodule CrosswordDataReader do
  def start_link(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> Map.get("info")
    |> Map.get("title")
  end
end
