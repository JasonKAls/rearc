# A Quest in the Clouds!

## links to work:

* [Site](http://rearc.jasonkals.com)
* [Github](https://github.com/JasonKAls/rearc)
* [Docker Image](https://hub.docker.com/repository/docker/jasonkals/reacrquestdemo)

## Instructions

1. Install Docker, Azure CLI, Terraform, and Kubernetes. Be sure to sign into your cloud account.
2. Apply the base configuration first. This separates the Resource Group and other important resources from the application's infrastructure needs: `cd ../base; terraform init; terraform plan -out plan.out; terraform apply plan.out`
3. Upload your docker image/s to your docker hub account and/or Azure Container Registry (ACR).
4. In the `rearc.yaml` file, be sure to modify the images name to the one your created. 
5. Apply the kubernetes file after signing into the cluster `kubectl apply -f rearc.yaml`
6. You should be able to use the clusters public IP in a browser to make sure everything is working properly.
7. Pat yourself on the back!

## What's Included

* Dockerfile: A containerized version of the application
* Azure AKS cluster via Terraform
* Terraform configuration files. Oganized in a safer pattern of operation.
* AWS Example.
* Variables file with terraform.tfvars for convenience in modifications.
* ...and more! All your money back!

## Shortcomings

* Couldn't use https cert since my domain is hosted in AWS. :(
* Time (lots of interviews! Other personal matters).
* Local setup: I mostly did projects on my work computer and has to setup everything on my personal desktop!

## "Given more time, I would improve..."

* Modularity: Create modules so code is organized and more abstract to the user.
* Build it in AWS: Then I could have my subdomain working properly!
* More Datasources: Some things were already built and reusable.