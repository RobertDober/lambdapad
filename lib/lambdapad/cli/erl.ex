defmodule Lambdapad.Cli.Erl do
  @moduledoc """
  Performs the compilation of the Erlang configuration file. The
  `index.erl` file, that's the file expected to be loaded as the
  code from Erlang, it's compiled on-the-fly and the defined
  functions are used for the configuration.
  """
  alias Lambdapad.Cli

  @compiler_opts ~w[
    return_errors
    return_warnings
    nowarn_export_all
    export_all
  ]a

  @doc """
  Performs the compilation of the Erlang code.
  """
  def compile(index_file) do
    :code.purge(:index)

    case :compile.file(String.to_charlist(index_file), @compiler_opts) do
      {:ok, mod, []} ->
        {:module, ^mod} = :code.load_file(mod)
        {:ok, {__MODULE__, mod}}

      {:ok, mod, warns} ->
        for warn <- warns do
          Cli.print_level2_warn(warn)
        end

        {:ok, {__MODULE__, mod}}

      {:error, errors, warns} ->
        IO.puts("\n---")

        for warn <- warns do
          Cli.print_level2_warn(warn)
        end

        for {filename, lines} <- errors do
          Cli.print_error("Found #{length(lines)} error(s) in #{filename}")

          for {{row, col}, error, description} <- lines do
            Cli.print_level2_error(filename, row, col, error, description)
          end
        end

        System.halt(1)
    end
  end

  def get_configs({__MODULE__, mod}, rawargs) do
    if function_exported?(mod, :config, 1) do
      for config <- mod.config(rawargs), do: translate_config(config)
    else
      [
        %{
          format: :eterm,
          from: "lambdapad.config"
        }
      ]
    end
  end

  defp assert_config_type(kind) do
    unless kind in Lambdapad.Config.valid_configs() do
      raise """
      The kind #{kind} isn't a valid configuration type, the valid
      configuration types are:

      #{inspect(Lambdapad.Config.valid_configs())}
      """
    end
  end

  defp translate_config({key, {kind, file}}) do
    assert_config_type(kind)
    %{format: kind, from: to_string(file), var_name: to_string(key)}
  end

  defp translate_config({kind, file}) do
    assert_config_type(kind)
    %{format: :eterm, from: to_string(file)}
  end

  def get_widgets({__MODULE__, mod}, config) do
    if function_exported?(mod, :widgets, 1) do
      for widget <- mod.widgets(config), into: %{} do
        {key, value} = translate_page_data(widget)

        {
          key,
          value
          |> Map.delete(:uri)
          |> Map.delete(:uri_type)
          |> Map.delete(:paginated)
        }
      end
    else
      %{}
    end
  end

  def get_pages({__MODULE__, mod}, config) do
    if function_exported?(mod, :pages, 1) do
      for page <- mod.pages(config), do: translate_page_data(page)
    else
      Cli.print_error("pages it's not defined into Erlang index.")
    end
  end

  defp pages_default() do
    %{
      uri_type: :dir,
      index: false,
      paginated: false,
      format: :erlydtl,
      headers: true,
      excerpt: true,
      from: nil,
      var_name: "page",
      env: %{}
    }
  end

  defp translate_page_data({uri, {:template, template, :undefined, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        index: true,
        uri: to_string(uri),
        template: to_string(template)
      })
    }
  end

  defp translate_page_data({uri, {:template, template, {var_name, from}, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        index: true,
        uri: to_string(uri),
        template: to_string(template),
        var_name: to_string(var_name),
        from:
          cond do
            is_nil(from) -> nil
            is_list(from) -> to_string(from)
            :else -> from
          end
      })
    }
  end

  defp translate_page_data({uri, {:template_map, template, :undefined, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        uri: to_string(uri),
        template: to_string(template)
      })
    }
  end

  defp translate_page_data({uri, {:template_map, template, {var_name, from}, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        var_name: to_string(var_name),
        uri: to_string(uri),
        template: to_string(template),
        from:
          cond do
            is_nil(from) -> nil
            is_list(from) -> to_string(from)
            :else -> from
          end
      })
    }
  end

  defp translate_page_data(unknown) do
    raise """
    page data unknown: #{inspect(unknown)}
    """
  end

  def get_assets({__MODULE__, mod}, config) do
    if function_exported?(mod, :assets, 1) do
      for {name, {from, to}} <- mod.assets(config), into: %{} do
        {to_string(name), %{from: to_string(from), to: to_string(to)}}
      end
    else
      %{"general" => %{from: "assets/**", to: "site/"}}
    end
  end

  def apply_transform({__MODULE__, _mod}, items), do: items

  def get_checks({__MODULE__, _mod}), do: []
end
