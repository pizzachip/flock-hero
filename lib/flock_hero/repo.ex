defmodule FlockHero.Repo do
  use Ecto.Repo,
    otp_app: :flock_hero,
    adapter: Ecto.Adapters.Postgres
end
