defmodule DiopCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :diop_core,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger,],
      mod: {DiopCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mime, "~> 1.3"},
      {:diop_email, path: "apps/diop_email"},
      {:diop_csv, path: "apps/diop_csv"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
