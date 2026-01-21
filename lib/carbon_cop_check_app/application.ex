defmodule CarbonCopCheckApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CarbonCopCheckAppWeb.Telemetry,
      CarbonCopCheckApp.Repo,
      {DNSCluster, query: Application.get_env(:carbon_cop_check_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CarbonCopCheckApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CarbonCopCheckApp.Finch},
      # Start a worker by calling: CarbonCopCheckApp.Worker.start_link(arg)
      # {CarbonCopCheckApp.Worker, arg},
      # Start to serve requests, typically the last entry
      CarbonCopCheckAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarbonCopCheckApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CarbonCopCheckAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
