defmodule DynamoProject.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dializer: [
        plt_add_deps: :apps_direct
      ],
      aliases: [
        test: "test --no-start"
      ],
      releases: [
        foo: [
          version: "0.0.1",
          applications: [dynamo: :permanent],
          cookie: "weknoweachother"
        ],
        bar: [
          version: "0.0.1",
          applications: [dynamo: :permanent],
          cookie: "weknoweachother"
        ],
        baz: [
          version: "0.0.1",
          applications: [dynamo: :permanent],
          cookie: "weknoweachother"
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:local_cluster, "~> 1.2", only: [:test]}
    ]
  end
end
