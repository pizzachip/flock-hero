ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FlockHero.Repo, :manual)
import Req.Test, only: [stub: 2]
Mox.defmock(JokenMock, for: Joken.CurrentTime.Behaviour)  # But Joken is not a behaviour; for module mocking, use alias or stub.
