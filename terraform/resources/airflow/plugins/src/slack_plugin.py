from airflow.plugins_manager import AirflowPlugin
from hooks.slack_webhook_hook import SlackWebhookHook
from operators.slack_webhook_operator import SlackWebhookOperator

class slack_webhook_operator(SlackWebhookOperator):
  pass

class slack_webhook_hook(SlackWebhookHook):
  pass

class slack_plugin(AirflowPlugin):

    name = 'my_slack_plugin'       
    hooks = [slack_webhook_hook]
    operators = [slack_webhook_operator]
