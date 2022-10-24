defmodule ExAwsMskIamAuth do
  @moduledoc """
  SASL AWS_MSK_IAM auth backend implementation for brod Erlang library.
  To authenticate, supply aws_secret_key_id and aws_secret_access_key with access to MSK cluster
  """
  @behaviour :kpro_auth_backend
  require Logger

  @kpro_lib Application.compile_env(:ex_aws_msk_iam_auth, :kpro_lib, KafkaProtocolLib)
  @signed_payload_generator Application.compile_env(
                              :ex_aws_msk_iam_auth,
                              :signed_payload_generator,
                              SignedPayloadGenerator
                            )

  @handshake_version 1

  def auth(
        _host,
        _sock,
        _mod,
        _client_id,
        _timeout,
        _sasl_opts = {_mechanism = :AWS_MSK_IAM, aws_secret_key_id, _aws_secret_access_key}
      )
      when aws_secret_key_id == nil,
      do: {:error, "AWS Secret Key ID is empty"}

  def auth(
        _host,
        _sock,
        _mod,
        _client_id,
        _timeout,
        _sasl_opts = {_mechanism = :AWS_MSK_IAM, _aws_secret_key_id, aws_secret_access_key}
      )
      when aws_secret_access_key == nil,
      do: {:error, "AWS Secret Access Key is empty"}

  # The following code is based on the implmentation of SASL handshake implementation from kafka_protocol Erlang library
  # Ref: https://github.com/kafka4beam/kafka_protocol/blob/master/src/kpro_sasl.erl
  @impl true
  @spec auth(
          any(),
          port(),
          :gen_tcp | :ssl,
          binary(),
          :infinity | non_neg_integer(),
          {:AWS_MSK_IAM, binary(), binary()}
        ) ::
          :ok | {:error, any()}
  def auth(
        host,
        sock,
        mod,
        client_id,
        timeout,
        _sasl_opts = {mechanism = :AWS_MSK_IAM, aws_secret_key_id, aws_secret_access_key}
      )
      when is_binary(aws_secret_key_id) and is_binary(aws_secret_access_key) do
    with :ok <- handshake(sock, mod, timeout, client_id, mechanism, @handshake_version) do
      client_final_msg =
        @signed_payload_generator.get_msk_signed_payload(
          host,
          DateTime.utc_now(),
          aws_secret_key_id,
          aws_secret_access_key
        )

      server_final_msg = send_recv(sock, mod, client_id, timeout, client_final_msg)

      case @kpro_lib.find(:error_code, server_final_msg) do
        :no_error -> :ok
        other -> {:error, other}
      end
    else
      error ->
        Logger.error("Handshake failed #{error}")
        {:error, error}
    end
  end

  def auth(_host, _sock, _mod, _client_id, _timeout, _sasl_opts) do
    {:error, "Invalid SASL mechanism"}
  end

  defp send_recv(sock, mod, client_id, timeout, payload) do
    req = @kpro_lib.make(:sasl_authenticate, _auth_req_vsn = 0, [{:auth_bytes, payload}])
    rsp = @kpro_lib.send_and_recv(req, sock, mod, client_id, timeout)

    Logger.debug("Final Auth Response from server - #{inspect(rsp)}")

    rsp
  end

  defp cs([]), do: "[]"
  defp cs([x]), do: x
  defp cs([h | t]), do: [h, "," | cs(t)]

  defp handshake(sock, mod, timeout, client_id, mechanism, vsn) do
    req = @kpro_lib.make(:sasl_handshake, vsn, [{:mechanism, mechanism}])
    rsp = @kpro_lib.send_and_recv(req, sock, mod, client_id, timeout)
    error_code = @kpro_lib.find(:error_code, rsp)

    Logger.debug("Error Code field in initial handshake response : #{error_code}")

    case error_code do
      :no_error ->
        :ok

      :unsupported_sasl_mechanism ->
        enabled_mechanisms = @kpro_lib.find(:mechanisms, rsp)
        "sasl mechanism #{mechanism} is not enabled in kafka, "
        "enabled mechanism(s): #{cs(enabled_mechanisms)}"

      other ->
        other
    end
  end
end
