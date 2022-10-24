defmodule ExAwsMskIamAuthTest do
  use ExUnit.Case, async: true

  import Hammox

  setup :verify_on_exit!

  describe "auth/6" do
    test "invalid mechanism" do
      assert {:error, "Invalid SASL mechanism"} =
               ExAwsMskIamAuth.auth(
                 "localhost",
                 nil,
                 :ssl,
                 "client_id",
                 60_000,
                 {:INVALID_MECHANISM, "access_id", "access_secret"}
               )
    end

    test "empty secret/accessid type " do
      assert {:error, "AWS Secret Access Key is empty"} =
               ExAwsMskIamAuth.auth(
                 "localhost",
                 nil,
                 :ssl,
                 "client_id",
                 60_000,
                 {:AWS_MSK_IAM, "access_id", nil}
               )

      assert {:error, "AWS Secret Key ID is empty"} =
               ExAwsMskIamAuth.auth(
                 "host",
                 nil,
                 :ssl,
                 "client_id",
                 60_000,
                 {:AWS_MSK_IAM, nil, "access_secret"}
               )
    end

    test "valid authentication call with all required parameters set where socket is a dummy test port" do
      # Mocking reference and ports to static values throughout the authentication exchanges
      ref = Kernel.make_ref()
      port = Port.open({:spawn, "echo dummy_test_port"}, [:binary])

      KafkaProtocolLibMock
      |> expect(:make, fn :sasl_handshake, 1, [mechanism: :AWS_MSK_IAM] ->
        {:kpro_req, ref, :sasl_handshake, 1, false, [[<<0, 11>>, "AWS_MSK_IAM"]]}
      end)
      |> expect(:make, fn :sasl_authenticate,
                          0,
                          [
                            auth_bytes:
                              "{\"action\":\"kafka-cluster:Connect\",\"host\":\"localhost\",\"user-agent\":\"msk-elixir-client\",\"version\":\"2020_10_22\",\"x-amz-algorithm\":\"AWS4-HMAC-SHA256\",\"x-amz-credential\":\"aws_secret_key_id/20220422/us-east-2/kafka-cluster/aws4_request\",\"x-amz-date\":\"20220422T111006Z\",\"x-amz-expires\":\"900\",\"x-amz-signature\":\"c61229c0d58532b023d29207adb96801ffa963df9b96c3fd2e736e7b0986c343\",\"x-amz-signedheaders\":\"host\"}"
                          ] ->
        {:kpro_req, ref, :sasl_authenticate, 0, false,
         [
           [
             <<0, 0, 1, 196>>,
             "{\"action\":\"kafka-cluster:Connect\",\"host\":\"localhost\",\"user-agent\":\"msk-elixir-client\",\"version\":\"2020_10_22\",\"x-amz-algorithm\":\"AWS4-HMAC-SHA256\",\"x-amz-credential\":\"aws_secret_key_id/20220422/us-east-2/kafka-cluster/aws4_request\",\"x-amz-date\":\"20220422T111006Z\",\"x-amz-expires\":\"900\",\"x-amz-signature\":\"c61229c0d58532b023d29207adb96801ffa963df9b96c3fd2e736e7b0986c343\",\"x-amz-signedheaders\":\"host\"}"
           ]
         ]}
      end)

      KafkaProtocolLibMock
      |> expect(:send_and_recv, fn {:kpro_req, _ref, :sasl_handshake, 1, false,
                                    [[<<0, 11>>, "AWS_MSK_IAM"]]},
                                   _port,
                                   :ssl,
                                   "client_id",
                                   60000 ->
        %{error_code: :no_error, mechanisms: ["AWS_MSK_IAM"]}
      end)
      |> expect(:send_and_recv, fn {:kpro_req, _ref, :sasl_authenticate, 0, false,
                                    [
                                      [
                                        <<0, 0, 1, 196>>,
                                        "{\"action\":\"kafka-cluster:Connect\",\"host\":\"localhost\",\"user-agent\":\"msk-elixir-client\",\"version\":\"2020_10_22\",\"x-amz-algorithm\":\"AWS4-HMAC-SHA256\",\"x-amz-credential\":\"aws_secret_key_id/20220422/us-east-2/kafka-cluster/aws4_request\",\"x-amz-date\":\"20220422T111006Z\",\"x-amz-expires\":\"900\",\"x-amz-signature\":\"c61229c0d58532b023d29207adb96801ffa963df9b96c3fd2e736e7b0986c343\",\"x-amz-signedheaders\":\"host\"}"
                                      ]
                                    ]},
                                   _port,
                                   :ssl,
                                   "client_id",
                                   60000 ->
        %{
          auth_bytes:
            "{\"version\":\"2020_10_22\",\"request-id\":\"77ab1dd9-1e70-4eb9-92be-78b69273e118\"}",
          error_code: :no_error,
          error_message: ""
        }
      end)

      KafkaProtocolLibMock
      |> expect(:find, fn :error_code, %{error_code: :no_error, mechanisms: ["AWS_MSK_IAM"]} ->
        :no_error
      end)
      |> expect(:find, fn :error_code,
                          %{
                            auth_bytes:
                              "{\"version\":\"2020_10_22\",\"request-id\":\"77ab1dd9-1e70-4eb9-92be-78b69273e118\"}",
                            error_code: :no_error,
                            error_message: ""
                          } ->
        :no_error
      end)

      SignedPayloadGeneratorMock
      |> expect(:get_msk_signed_payload, fn "localhost", _, "access_id", "access_secret" ->
        "{\"action\":\"kafka-cluster:Connect\",\"host\":\"localhost\",\"user-agent\":\"msk-elixir-client\",\"version\":\"2020_10_22\",\"x-amz-algorithm\":\"AWS4-HMAC-SHA256\",\"x-amz-credential\":\"aws_secret_key_id/20220422/us-east-2/kafka-cluster/aws4_request\",\"x-amz-date\":\"20220422T111006Z\",\"x-amz-expires\":\"900\",\"x-amz-signature\":\"c61229c0d58532b023d29207adb96801ffa963df9b96c3fd2e736e7b0986c343\",\"x-amz-signedheaders\":\"host\"}"
      end)

      assert :ok =
               ExAwsMskIamAuth.auth(
                 "localhost",
                 port,
                 :ssl,
                 "client_id",
                 60_000,
                 {:AWS_MSK_IAM, "access_id", "access_secret"}
               )
    end
  end
end
