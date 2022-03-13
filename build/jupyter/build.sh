docker login

docker build -t jupyter-spark:3.2.0-aws-sdk-1.12.132 .

docker tag jupyter-spark:3.2.0-aws-sdk-1.12.132 angelmaroco/jupyter-spark:3.2.0-aws-sdk-1.12.132

docker push angelmaroco/jupyter-spark:3.2.0-aws-sdk-1.12.132
