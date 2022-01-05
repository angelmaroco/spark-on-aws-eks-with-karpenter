#!/bin/bash

docker login

docker build -t spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8 .

docker tag spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8 angelmaroco/spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8

docker push angelmaroco/spark:3.2.0-hadoop-3.2-aws-sdk-1.12.132-python-3.8
