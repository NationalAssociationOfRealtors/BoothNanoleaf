defmodule BoothNanoleaf.CO2 do
  use GenServer
  require Logger

  @nano :"uuid:3aebec1d-2709-415e-a75a-88a1e0725dd3" #update this with the UDN of your nanoleaf
  @panels [46, 178, 54, 132, 228, 235, 27, 120, 242, 110, 152, 149] # these are panel id's in order of rendering
  @api_key "EXIKpkqbDmsywejvEF8BrAXdi6baDBRP"
  @id "IEQStation-38"

  defmodule EventHandler do
    use GenEvent
    require Logger

    def handle_event(%IEQGateway.IEQStation.State{} = device, parent) do
      send(parent, device)
      {:ok, parent}
    end

    def handle_event(_device, parent) do
      {:ok, parent}
    end

    def terminate(reason, parent) do
      Logger.info "IEQ Sensor EventHandler Terminating: #{inspect reason}"
      :ok
    end

  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    co2 = 1..12 |> Enum.map(fn(i) -> Enum.random(500..1699) end)
    Process.send_after(self(), :check_network, 5_000)
    {:ok, %{co2: co2}}
  end

  def handle_info(:check_network, state) do
    case BoothNanoleaf.Network.connected? do
      true -> Process.send_after(self(), :start, 0)
      false -> Process.send_after(self(), :check_network, 500)
    end
    {:noreply, state}
  end

  def handle_info(:start, state) do
    SSDP.Client.start()
    :timer.sleep(5000)
    Nanoleaf.Device.set_api_key(@nano, @api_key)
    IEQGateway.Events |> GenEvent.add_mon_handler(EventHandler, self())
    {:noreply, state}
  end

  def handle_info(%IEQGateway.IEQStation.State{id: :"IEQStation-38"} = device, state) do
    Logger.info "Got data: #{inspect device}"
    current = [1699, device.co2] |> Enum.min
    co2 = state.co2 |> Enum.drop(-1) |> (fn l -> [current] ++ l end).()
    multi = 0.15
    frame = gen_frame(co2, multi)
    Nanoleaf.Device.write(@nano, %{write: %{command: "display", version: "1.0", animType: "custom", animData: frame, loop: false}})
    {:noreply, %{state | co2: co2}}
  end

  def handle_info(%IEQGateway.IEQStation.State{}, state), do: {:noreply, state}

  def gen_frame(co2, multi) do
    0..11 |> Enum.reduce("12", fn(i, acc) ->
      v = co2 |> Enum.at(i)
      id = @panels |> Enum.at(i)
      r = round(v * multi)
      g = 50
      b = 255
      "#{acc} #{id} 1 #{r} #{g} #{b} 1 20"
    end)
  end
end
