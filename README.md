# sample-go-orchestration

This repository contains terraform templates to create a simple 2 tiers infrastructure in an AWS environment.
https://www.terraform.io/


It will create :

* 2 x application nodes
* 1 x web node

The application nodes will run the sample-go app => https://github.com/jujugrrr/sample-go
The web node wil run a nginx server configured as a load-balancer to send request to the application nodes
The terraform template will create other required resources, VPC, security groups, key pairs etc...

# Requirements

* you need terraform to be installed : https://www.terraform.io/intro/getting-started/install.html
* you need an AWS account, an access_key, and access_key_secret and the approriate permissions :

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

# Usage

Clone the repository

`$ git clone https://github.com/jujugrrr/sample-go-orchestration.git`

Check what terraform will do :

```
$ terraform plan
Refreshing Terraform state prior to plan...

aws_key_pair.auth: Refreshing state... (ID: terraform)
aws_vpc.default: Refreshing state... (ID: vpc-a9feefcc)
aws_internet_gateway.default: Refreshing state... (ID: igw-14713571)
aws_security_group.web: Refreshing state... (ID: sg-c26173a6)
aws_subnet.default: Refreshing state... (ID: subnet-e11129b8)
aws_security_group.application: Refreshing state... (ID: sg-c16173a5)
aws_route.internet_access: Refreshing state... (ID: r-rtb-fabf799e1080289494)
aws_instance.application1: Refreshing state... (ID: i-0284428e)
aws_instance.application2: Refreshing state... (ID: i-658442e9)
aws_instance.web: Refreshing state... (ID: i-ff935573)
```

** Run the stack **

```
$ terraform apply
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

  webnode = 54.229.151.170
```

You can test it works with a simple `curl`

```
$ curl 54.229.151.170
 Hi there, I'm served from ip-10-0-1-29!
$ curl 54.229.151.170
 Hi there, I'm served from ip-10-0-1-205!
```

# Design choices

I've used Terraform over CloudFormation due to its simplicity, readability and ability to "plan" a change/update.
I've used chef-solo to reduce the complexity of having a Chef server infrastructure. I wanted to try an "artifact" approach.
It's mainly a proof of concept, we would need more network isolation. The solution is not HA, and cannot really scale. It's idempotent though.

## Todo

* Use autoscale groups for web and application
* Have dedicated network for web (public) and application(private + NAT)
* Improve output
* Add more variables (AMI, etc...)
* Implement code-deploy so we don't need to run Chef again for a new code deployment
* use ELB or some DNS update to load-balancer the web nodes
* Test Terraform in circleci
* Centralized terraform state
