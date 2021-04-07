defmodule Lambdapad.MixProject do
  use Mix.Project

  def project do
    [
      name: "Lambdapad",
      description: "Static website creator",
      app: :lambdapad,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      name: "Lambdapad",
      homepage_url: "https://lambdapad.com"
    ]
  end

  defp escript do
    [
      main_module: Lambdapad.Cli,
      name: "lpad"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp deps do
    [
      {:earmark, github: "manuel-rubio/earmark"},
      {:erlydtl, github: "manuel-rubio/erlydtl"},
      {:pockets, "~> 1.0"},
      {:toml, "~> 0.6"},
      {:optimus, "~> 0.2"}
    ]
  end
end
