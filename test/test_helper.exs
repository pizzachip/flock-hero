ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FlockHero.Repo, :manual)
Mox.defmock(ReqMock, for: Req.Request)
Mox.defmock(JokenMock, for: Joken.CurrentTime.Behaviour)  # But Joken is not a behaviour; for module mocking, use alias or stub.
