defmodule Vnode.Manager do
  @moduledoc """
  Utility function for vnodes
  """

  use GenServer

  @type index_as_int() :: integer()

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end


  # Return the PID of parition index.
  # If the index is not in the index_table, start the vnode first
  # and update the index_table and return the pid
  @spec get_vnode(index_as_int()) :: pid()
  defp get_vnode(index) do
    pid = Agent.get(:index_table, fn table -> Map.get(table, index, :none) end)

    case pid do
      :none ->
        {:ok, pid} = DynamicSupervisor.start_child(Vnode.Supervisor, {Vnode, index})
        Agent.update(:index_table, fn table -> Map.put(table, index, pid) end)
        pid
      _ -> pid
    end
  end

  @doc """
  Return the PID of partition index
  """
  @spec get_vnode_pid(index_as_int()) :: pid()
  def get_vnode_pid(index) do
    GenServer.call(__MODULE__, {:get_vnode, index}, :infinity)
  end

  @doc """
  This is part of initialization process. It starts all the vnode.
  """
  def start_ring do
    {:ok, ring} = Ring.Manager.get_my_ring

    startable_vnodes = Ring.my_indices(ring)
    for index <- startable_vnodes do
       Vnode.start_vnode(index)
    end
  end

  @impl true
  def init(:ok) do
    Agent.start_link(fn -> %{} end, name: :index_table)
    {:ok, []}
  end

  @impl true
  def handle_call({:get_vnode, index}, _from, state) do
    pid = get_vnode(index)
    {:reply, pid, state}
  end
end