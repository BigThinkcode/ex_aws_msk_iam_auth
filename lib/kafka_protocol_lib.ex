defmodule KafkaProtocolLib do
  @moduledoc """
  KafkaProtocolLib module is a facade behavior/implementation for Erlang's Kafka Protocl library modules
  Ref: https://github.com/kafka4beam/kafka_protocol
  Contains wrapper functions for methods in kpro, kpro_lib and kpro_req_lib modules
  Purpose: Creating this as a behavior helps us mock the network calls made during authentication exchanges
  """

  @callback find(atom() | integer(), map() | list()) :: atom() | binary() | list(any())
  def find(field, struct), do: :kpro.find(field, struct)

  @callback make(atom(), non_neg_integer(), list() | map()) ::
              {:kpro_req, reference(), atom(), non_neg_integer(), false,
               binary() | list() | map()}
  def make(api, version, fields), do: :kpro_req_lib.make(api, version, fields)

  @callback send_and_recv(
              {:kpro_req, reference(), atom(), non_neg_integer(), boolean(),
               binary() | list() | map()},
              port(),
              atom(),
              binary(),
              :infinity | non_neg_integer()
            ) :: list({atom() | integer(), any()}) | map()
  def send_and_recv(req, sock, mod, client_id, timeout),
    do: :kpro_lib.send_and_recv(req, sock, mod, client_id, timeout)
end
