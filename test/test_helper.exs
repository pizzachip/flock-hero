ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FlockHero.Repo, :manual)

Mox.defmock(Joken.CurrentTime.Mock, for: Joken.CurrentTime)  # Keep this—it's global for all tests using the mock
