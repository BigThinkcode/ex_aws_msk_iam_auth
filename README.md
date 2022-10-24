# ex_aws_msk_iam_auth

`ex_aws_msk_iam_auth` is an authentication plugin for broadway_kafka. It enables Broadway Kafka clients to authenticate with Amazon's Managed Streaming for Apache Kafka(Amazon MSK) via [AWS_MSK_IAM](https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html) SASL mechanism.


## Installation

Add the following dependency to your `mix.exs`
```elixir
def deps do
  [
    {:ex_aws_msk_iam_auth, git: "https://github.com/BigThinkcode/ex_aws_msk_iam_auth"}
  ]
end
```

## Usage

Broadway Kafka supports connecting to Kafka broker via SASL authentication. The following sample configuration shows how `ex_aws_msk_iam_auth` plugin can be used with it.
 
Ref: https://hexdocs.pm/broadway_kafka/BroadwayKafka.Producer.html#module-client-config-options

```elixir
  client_config: [
            sasl:
              {
                :callback, 
                AwsMskIam, 
                {:AWS_MSK_IAM, "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"}
              },
            ssl: true
          ]
```

## Background

### Broadway Kafka and brod
[Broadway Kafka](https://github.com/dashbitco/broadway_kafka) is a Kafka Connector for [Broadway](https://github.com/dashbitco/broadway) - an Elixir library to build concurrent, multi-stage data ingestion/processing pipelines with Elixir.
Broadway Kafka is an amalgamation of awesome features from Broadway with Kafka as a producer. Internally, it uses [brod](https://github.com/kafka4beam/brod) as its Kafka client acting as a wrapper. Brod supports `SASL PLAIN`, `SCRAM-SHA-256` and `SCRAM-SHA-512` authentication mechanisms out of the box and also offers extension points to support custom [authentication plugins](https://github.com/kafka4beam/brod#authentication-support). 

### AWS MSK Authentication Mechanisms
MSK supports two variants - MSK Fully Managed and MSK Serverless. In both the variants, Kafka service can be protected via SASL, in particular, AWS's custom SASL mechanism AWS_MSK_IAM(https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html). At the time of writing this library, MSK's Serverless variant's only supported authentication was AWS_MSK_IAM SASL mechanism.

### Implementation
This library takes inspiration from its Java counterpart [aws-msk-iam-auth](https://github.com/aws/aws-msk-iam-auth)

### Relevant Issues/PRs
1. https://github.com/dashbitco/broadway_kafka/issues/82
2. https://github.com/dashbitco/broadway_kafka/pull/85
3. https://github.com/aws-beam/aws_signature/issues/14
