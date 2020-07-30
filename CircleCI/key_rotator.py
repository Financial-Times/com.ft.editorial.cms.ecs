#!/usr/bin/env /usr/bin/python3
#
# USAGE
# 1. Create API token in CircleCI project
#    Project Settings -> Permissions -> API Permissions -> Create Token -> Add an API token: All -> Add Token
#
# 2. Add API token to CredStash table cms-methode-credential-store with key CircleCI.<projectname>.apikey
#    EXAMPLE: credstash -r eu-west-1 -t cms-methode-credential-store put -a CircleCI.com.ft.editorial.cms.servlets.mms.apikey 123asd567qwe
#
# 3. Prepare runtime environment
#
#    Option 1. Install depenencies
#    apk add --no-cache openjdk8 ca-certificates openssl bash curl python3 python3-dev py3-pip openssl-dev libffi-dev build-base
#    pip3 install requests credstash
#
#    Option 2. Use key-rotator docker image. Include all dependencies. Run these commands on any ECS cluster node
#    ECR login: $(aws ecr --region eu-west-1 get-login --no-include-email)
#    Add credstash credentials to temp file eg. /tmp/credentials
#       [default]
#       aws_access_key_id = whatever
#       aws_secret_access_key = everwhat
#    Run container: docker run -v /tmp:/root/.aws -it 307921801440.dkr.ecr.eu-west-1.amazonaws.com/key-rotator:1 /bin/bash
#    Update AWS credentials in credstash:
#       credstash -r eu-west-1 -t cms-methode-credential-store put -a CircleCI.AWS.key value
#       credstash -r eu-west-1 -t cms-methode-credential-store put -a CircleCI.AWS.secret value
#    Update CircleCI projects
#       ./key_rotator.py


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
