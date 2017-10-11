# ECS Cluster


Templates requires IAM role ECSInstanceRole with the following policies defined.

```
---
AWSTemplateFormatVersion: "2010-09-09"
Description: IAM role for ECS instance, incorporates FT-Linux-Role polies and AmazonEC2ContainerServiceforEC2Role
Resources:
  ECSInstanceRole:
    Type: "AWS::IAM::Role"
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
      Policies:
        - FT-Linux-Policy
        - FT-SSM-Policy
      RoleName: ECSInstanceRole
      ```
