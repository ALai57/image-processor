
## Image processor

This repository houses a Python function meant to be used as an AWS lambda that
processes incoming files by shrinking the file to a specific size.

### Some resources
https://github.com/mineiros-io/terraform-aws-lambda-function/tree/v0.5.0/examples/python-function
https://github.com/awsdocs/aws-lambda-developer-guide/blob/main/doc_source/python-package.md

TODO:

Lambda actually processes image - and tests for it

### Local development

``` sh
source env/bin/activate

```

``` sh
# Install Boto3, but don't add to src directory because
# AWS already includes it
pip install boto3

# Install requirements into src directory because we need to 
# manually add them and package them together
pip install --target src/deps -r requirements.txt
```

