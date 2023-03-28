#Ce code crée un groupe de sécurité qui permet à la fois l'accès SSH et HTTP à WordPress, 
#une instance EC2 qui exécute le code d'installation et de configuration de WordPress, 
#une base de données RDS pour stocker les données de WordPress, 
#une adresse IP élastique pour faciliter l'accès à l'instance EC2 et une ressource pour lier l'adresse IP élastique à l'instance EC2
provider "aws" {
  region = "us-west-2"
  profile = "default"
}

# Création du groupe de sécurité pour WordPress
resource "aws_security_group" "wordpress" {
  name_prefix = "wordpress-"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Création de l'instance EC2 pour WordPress
resource "aws_instance" "wordpress" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name = "my-key-pair"
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd24 php56 mysql56-server php56-mysqlnd
              service httpd start
              chkconfig httpd on
              groupadd www
              usermod -a -G www ec2-user
              chown -R root:www /var/www
              chmod 2775 /var/www
              find /var/www -type d -exec chmod 2775 {} +
              find /var/www -type f -exec chmod 0664 {} +
              cd /var/www/html
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz --strip-components=1
              EOF
}

# Création de la base de données RDS pour WordPress
resource "aws_db_instance" "wordpress" {
  engine = "mysql"
  engine_version = "5.6"
  instance_class = "db.t2.micro"
  allocated_storage = 5
  identifier = "wordpress"
  username = "wordpress"
  password = "mypassword"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.wordpress.id]
}

# Création d'une adresse IP élastique pour l'instance EC2
resource "aws_eip" "wordpress" {
  instance = aws_instance.wordpress.id
}

# Création d'une ressource pour lier l'adresse IP élastique à l'instance EC2
resource "aws_eip_association" "wordpress" {
  instance_id = aws_instance.wordpress.id
  allocation_id = aws_eip.wordpress.id
}
