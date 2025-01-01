CI/CD For Flask Contact App in Kubernetes cluster, with a Load Balancer

Instructions:

1- Download the following apps:
a-aws cli
b-dockers
c-terraform
d-kubectl
e-ansible
f-helm
h-git
g-all the required programs in order to run those apps.

2- Clone the github repository: "https://github.com/glazedonuts616/MajorProject.git"

3- Add Private Key Credential from Aws to the computer running the repository, and place it in the .aws folder


4- Attach to the awscli with your credentials

5- Change the key name in the aws_instance, to the same name of your aws-key file, which you have placed in .aws folder.

6- Move to the folder "MajorProject/terraform/" and run terraform init, plan, apply.

7- Move to the folder "MajorProject/terraform/tf_ec2_ansible/" make sure you update the inventory.ini file is updated with the location of your aws key,
and then run "ansible-playbook -i inventory.ini ec2_ansible.yaml"

8- Connect to your new ec2 with ssh -i "path-to-your-key" ubunto@"Your-EIP-address"

9- Go in to the docker logs of Jenkins, copy the password

10- Enter the IP Address of your EIP in the url of your browser,  connect through port 8080, and place the jenkins admin password.

11- Once in Jenkins, install the following plugins.
a- EKS token
b- EC2
c- git
d- Kubernetes
e- Pipeline: groovy, Pipeline - grid view
f- Amazon Web services

12- Add the neccasary credentials:
a- 	EKS Token Credentials
b- AWS Credentials
c- github
d-  github webhook

12- move to the folder "MajorProject/terraform/eks_cluster" and run terraform init, terrafor plan, apply

13- make sure the printers are up to date, with a connection to the server.

13- Navigate back to jenkins, which is in the ec2 we created originally, with the eip address. Enter web interface in url.

14- Take the Jenkinsfile and put it in the pipeline, with the correct cluster ednpoint url, fill in the box to synchronize printer from github webhook. and build the pipline.

15- go to the dns name given to the loadbalancer, and at port 5052 is our flask contact app, at 8081 is the mongoDB.

16- Once making sure all the info is corect for the github, on github and in jenkins for a webhook, you can also see the success of pushing into the github repo.


It's been real!
Yoni









[1- Run terraform to start first cloud computer with jenkins already on it.
2- Ansible to install the required programs[ python, pip,] on the ec2.
3: Terraform for eks, and elb
4. Ansible, credentials, and pipeline for the flask-app to run on the eks
5. Push to github of files.
6. Webhook for github
7. Test one by one.
8.Checking WEBHOOK!!
]