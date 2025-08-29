```
aws --region us-east-1 cloudformation update-stack --stack-name demo \
--template-body https://s3.amazonaws.com/hybox-deployment-artifacts/cloudformation/branch/master/templates/stack.yaml \
--capabilities CAPABILITY_IAM --parameters file://params/parameters.json
```