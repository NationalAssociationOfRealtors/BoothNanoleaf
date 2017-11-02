defmodule BoothNanoleaf.WebSocketHandler do
  require Logger
  @behaviour :cowboy_websocket_handler
  @timeout 60000

  defmodule EventHandler do
    use GenEvent
    require Logger

    def handle_event(%IEQGateway.IEQStation.State{id: :"IEQStation-22"} = device, parent) do
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

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_type, req, _opts) do
    IEQGateway.Events |> GenEvent.add_mon_handler({EventHandler, Enum.random(1..100_000)}, self())
    {:ok, req, %{}, @timeout}
  end

  def websocket_handle({:text, message}, req, state) do
    {:reply, {:text, message}, req, state}
  end

  def websocket_info(:shutdown, req, state) do
    {:shutdown, req, state}
  end

  def websocket_info(%IEQGateway.IEQStation.State{} = device, req, state) do
    {:reply, {:text, device |> Poison.encode!}, req, state}
  end

  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  def websocket_terminate(_reason, _req, _state), do: :ok
end
