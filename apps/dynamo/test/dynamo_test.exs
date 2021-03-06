defmodule DynamoTest do
  use ExUnit.Case

  # Please note that distributed test may fail from timeout in test enviroment
  @tag :distributed
  test "tcp connection" do
    [replication, read, write] = [3, 2, 2]
    [port1, port2, port3] = [4041, 4042, 4043]

    [node1] =
      LocalCluster.start_nodes("node-1", 1,
        files: [__ENV__.file],
        environment: [
          dynamo: [
            port: Integer.to_string(port1),
            replication: replication,
            R: read,
            W: write
          ]
        ]
      )

    [node2] =
      LocalCluster.start_nodes("node-2", 1,
        files: [__ENV__.file],
        environment: [
          dynamo: [
            port: Integer.to_string(port2),
            replication: replication,
            R: read,
            W: write
          ]
        ]
      )

    [node3] =
      LocalCluster.start_nodes("node-3", 1,
        files: [__ENV__.file],
        environment: [
          dynamo: [
            port: Integer.to_string(port3),
            replication: replication,
            R: read,
            W: write
          ]
        ]
      )

    {:ok, socket1} = :gen_tcp.connect(:localhost, port1, [:binary, active: false])
    {:ok, socket2} = :gen_tcp.connect(:localhost, port2, [:binary, active: false])
    {:ok, socket3} = :gen_tcp.connect(:localhost, port3, [:binary, active: false])

    # joining cluster by joining any node in the cluster
    :gen_tcp.send(socket2, "JOIN node-11@127.0.0.1\n")
    :gen_tcp.send(socket3, "JOIN node-21@127.0.0.1\n")

    assert :gen_tcp.recv(socket2, 0) == {:ok, "Joining \"node-11@127.0.0.1\" \n"}
    assert :gen_tcp.recv(socket3, 0) == {:ok, "Joining \"node-21@127.0.0.1\" \n"}
    Process.sleep(1000)

    # put (hello, world) into the dynamo cluster
    :gen_tcp.send(socket1, "PUT hello world\n")
    assert :gen_tcp.recv(socket1, 0) == {:ok, "OK\n"}
    Process.sleep(10)

    # retrieving same value from any node in the cluster
    :gen_tcp.send(socket1, "GET hello\n")
    assert :gen_tcp.recv(socket1, 0) == {:ok, "world\n"}
    :gen_tcp.send(socket2, "GET hello\n")
    assert :gen_tcp.recv(socket2, 0) == {:ok, "world\n"}
    :gen_tcp.send(socket3, "GET hello\n")
    assert :gen_tcp.recv(socket3, 0) == {:ok, "world\n"}

    Node.spawn(node1, fn ->
      KV.put_single(
        "hello",
        "foo",
        913438523331814323877303020447676887284957839360
      )
    end)

    Node.spawn(node2, fn ->
      KV.put_single(
        "hello",
        "bar",
        548063113999088594326381812268606132370974703616
      )
    end)

    Node.spawn(node3, fn ->
      KV.put_single(
        "hello",
        "baz",
        730750818665451459101842416358141509827966271488
      )
    end)

    Process.sleep(100)
    :gen_tcp.send(socket2, "STABILIZE hello\n")
    {:ok, stabilization_time} = :gen_tcp.recv(socket2, 0)

    :gen_tcp.send(socket1, "GET hello\n")
    {:ok, value} = :gen_tcp.recv(socket1, 0)
    assert value == "bar, baz, foo\n"

    IO.puts "Stabilization time: #{stabilization_time}"
  end
end
