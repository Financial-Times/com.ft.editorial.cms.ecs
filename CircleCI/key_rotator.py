#!/usr/bin/env /usr/bin/python3

import credstash
import requests
import re
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-p", "--profile", dest="awsProfile",
                  default="default", type="string",
                  action="store", help="AWS CLI profile")

(options, noise) = parser.parse_args()

credstash.get_session(profile_name=options.awsProfile)

api_url = "https://circleci.com/api/v1.1/project/github/Financial-Times/"
header = {"Content-Type": "application/json"}

table = "cms-methode-credential-store"
key = "CircleCI.AWS.key"
secret = "CircleCI.AWS.secret"
aws_key = credstash.getSecret(key, region="eu-west-1", table=table)
aws_secret = credstash.getSecret(secret, region="eu-west-1", table=table)

aws_credentials = {"AWS_ACCESS_KEY_ID": aws_key, "AWS_SECRET_ACCESS_KEY": aws_secret}

api_key_pattern = re.compile("^CircleCI\..*\.apikey$")

all_secrets = credstash.listSecrets(region="eu-west-1", table=table)

repos_apikeys = [n['name'] for n in all_secrets if api_key_pattern.match(n['name'])]

for repo_apikey in repos_apikeys:
    repo = repo_apikey.replace('CircleCI.', '').replace('.apikey', '')
    print(repo)

    circle_token = credstash.getSecret(repo_apikey, region="eu-west-1", table=table)
    url = api_url + repo + "/envvar?circle-token=" + circle_token

    for k, v in aws_credentials.items():
        payload = {"name": k, "value": v}
        add_env_vars = requests.post(url, json=payload, headers=header)
        print(add_env_vars.text)

    print()
