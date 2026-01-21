defmodule CarbonCopCheckApp.Repo do
  use Ecto.Repo,
    otp_app: :carbon_cop_check_app,
    adapter: Ecto.Adapters.Postgres
end
