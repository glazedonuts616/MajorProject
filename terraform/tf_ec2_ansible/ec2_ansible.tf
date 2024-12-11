provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "jenkins-master" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  id = var.jenkins-master
  key_name      = "My-first-key"       # Replace with your key pair name

  provisioner "file" {
    source      = "my_script.py"          # Local Python script path
    destination = "/tmp/my_script.py"     # Remote path on the server
  }
    provisioner "remote-exec" {
    inline = [
    "sudo apt-get update -y",           # Example for Ubuntu
    "sudo apt-get install -y python3",  # Install Python
    "sudo apt-get install -y python3-pip",  # Install pip for Python 3
    "sudo pip install -r requirements.txt"
    ]
    }


  connection {
    type        = "ssh"
    user        = "ubuntu"                # Adjust for your server's OS
    private_key = file("~/.ssh/my-key.pem") # Replace with your private key
    host        = self.public_ip
  }

  tags = {
    Name = "Terraform-Ansible-Instance"
  }
}
