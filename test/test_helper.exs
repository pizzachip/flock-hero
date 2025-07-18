ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FlockHero.Repo, :manual)

import Req.Test, only: [stub: 2]
Mox.defmock(Joken.CurrentTime.Mock, for: Joken.CurrentTime)
