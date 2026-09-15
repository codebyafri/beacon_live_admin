defmodule Beacon.LiveAdmin.CallContextTest do
  use ExUnit.Case, async: false
  alias Beacon.LiveAdmin.Cluster

  defmodule Site do
    use GenServer
    def start_link(_), do: GenServer.start_link(__MODULE__, nil)
    def init(_), do: {:ok, nil}
    def handle_call(:current_node, _, state), do: {:reply, node(), state}
  end

  defmodule Context do
    def capture(site), do: {site, self(), Process.get(:test_call_identity)}

    def call(site, mod, fun, args, {site, caller, :verified}) do
      {caller, self(), apply(mod, fun, args)}
    end

    def call(_, _, _, _, _), do: raise("identity required")
  end

  setup do
    previous = Application.get_env(:beacon_live_admin, :call_context)
    pid = start_supervised!(Site)
    :ok = :pg.join(Cluster.scope(), :context_test_site, pid)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:beacon_live_admin, :call_context, previous),
        else: Application.delete_env(:beacon_live_admin, :call_context)
    end)

    :ok
  end

  test "default invocation remains unchanged" do
    Application.delete_env(:beacon_live_admin, :call_context)
    assert Cluster.call(:context_test_site, Enum, :sum, [[1, 2]]) == 3
  end

  test "explicit context works in both local and freshly spawned erpc calls" do
    Application.put_env(:beacon_live_admin, :call_context, Context)
    Process.put(:test_call_identity, :verified)
    caller = self()
    assert {^caller, _, 3} = Cluster.call(:context_test_site, Enum, :sum, [[1, 2]])
    context = Context.capture(:context_test_site)
    Process.delete(:test_call_identity)
    # erpc.call may optimize a same-node invocation into the caller process.
    # send_request guarantees the distinct process used for this boundary check.
    request =
      :erpc.send_request(node(), Context, :call, [
        :context_test_site,
        Enum,
        :sum,
        [[1, 2]],
        context
      ])

    assert {^caller, remote, 3} = :erpc.receive_response(request, 5_000)
    refute remote == caller
  end

  test "a rejected context does not fall back to invoking the target" do
    Application.put_env(:beacon_live_admin, :call_context, Context)

    assert_raise Beacon.LiveAdmin.ClusterError, ~r/identity required/, fn ->
      Cluster.call(:context_test_site, Enum, :sum, [[1, 2]])
    end
  end
end
