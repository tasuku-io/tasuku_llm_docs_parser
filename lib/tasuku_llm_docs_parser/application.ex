defmodule TasukuLlmDocsParser.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TasukuLlmDocsParserWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tasuku_llm_docs_parser, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TasukuLlmDocsParser.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TasukuLlmDocsParser.Finch},
      # Start a worker by calling: TasukuLlmDocsParser.Worker.start_link(arg)
      # {TasukuLlmDocsParser.Worker, arg},
      # Start to serve requests, typically the last entry
      TasukuLlmDocsParserWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TasukuLlmDocsParser.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TasukuLlmDocsParserWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
