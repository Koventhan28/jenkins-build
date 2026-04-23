locals {
  Jenkins_installation = <<-EOF
            #!/bin/bash
            sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo
            sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key
            sudo rpm --import https://yum.corretto.aws/corretto.key
            sudo curl -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
            sudo yum install java-21-amazon-corretto-devel -y
            sudo amazon-linux-extras install java-openjdk11 -y
            sudo yum install jenkins -y
            sudo yum install git docker -y
            sudo systemctl enable docker 
            sudo systemctl start docker 
            sudo systemctl enable jenkins
            sudo systemctl start jenkins
            sudo usermod -aG docker jenkins
            sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo chmod +x ./kubectl
            sudo mv ./kubectl /usr/local/bin/kubectl
            sudo wget https://get.helm.sh/helm-v3.15.1-linux-amd64.tar.gz
            sudo tar -zxvf helm-v3.15.1-linux-amd64.tar.gz
            sudo mv linux-amd64/helm /usr/local/bin/helm
            helm version
            EOF
}
##########################
# AMI ID for the Instance
##########################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # Official Amazon owner ID

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Ec2 Instance
############################
resource "aws_instance" "Jenkins" {
  count = 1
  provider               = aws.west
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.medium"
  
  subnet_id = element(aws_subnet.public[*].id, count.index)
  #subnet_id              = element(aws_subnet.public[count.index].id,)
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  user_data              = local.Jenkins_installation
  key_name               = "testing_west"
  tags = {
    "Name" = "Jenkins-Server"
  }
  # The below block is used for making sure the instance waits for 2/2 check is passed
    provisioner "local-exec" {
    # This command polls AWS every 15 seconds until status is 'ok' (2/2 passed)
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.Jenkins[0].id} --region ${var.region}"
  }
  

  }




############################
# Instance Output details
############################

output "use1_public_ip" {
  value = aws_instance.Jenkins[*].public_ip
}
