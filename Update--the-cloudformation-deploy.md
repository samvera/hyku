```
aws --region us-east-1 cloudformation update-stack --stack-name demo --template-body https://s3.amazonaws.com/hybox-deployment-artifacts/cloudformation/current/templates/stack.json  --capabilities CAPABILITY_IAM --parameters file://params/parameters.json
```