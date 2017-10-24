defmodule BoothNanoleaf.Network do
  use GenServer
  require Logger

  @target System.get_env("MIX_TARGET") || "host"

  def connected?, do: GenServer.call(__MODULE__, :connected?)
  def ip_addr, do: GenServer.call(__MODULE__, :ip_addr)

  def test_dns(hostname \\ 'nerves-project.org') do
   :inet_res.gethostbyname(hostname)
  end

  def start_link() do
    interface = Application.get_env(:booth_nanoleaf, :interface, :wlan0)
    GenServer.start_link(__MODULE__, interface |> to_string, name: __MODULE__)
  end

  def init(interface) do
    case @target do
      "host" -> nil
      _ ->
        Network.setup(interface)
        SystemRegistry.register
    end
    {:ok, %{ interface: interface, ip_address: nil, connected: false }}
    end

  def handle_info({:system_registry, :global, registry}, state) do
    ip = get_in registry, [:state, :network_interface, state.interface, :ipv4_address]
    s_ip = state.ip_address
    case ip do
      s_ip -> nil
      _ -> Logger.info "IP ADDRESS CHANGED: #{ip}"
    end
    connected = match?({:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}}, test_dns())
    {:noreply, %{state | ip_address: ip, connected: connected || false}}
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_call(:connected?, _from, state) do
    {:reply,
      case @target do
        "host" -> true
        _ -> state.connected
      end,
    state}
  end

  def handle_call(:ip_addr, _from, state), do: {:reply, state.ip_address, state}
end
