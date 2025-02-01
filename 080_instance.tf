resource "aws_instance" "web" {
  count         = 4
  ami           = "ami-0aa9ffd4190a83e11"
  instance_type = "t2.micro"
  subnet_id     = element([aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_3.id], count.index)
  key_name      = var.key_name
  user_data     = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd git php php-mysqli mariadb105
        systemctl start httpd
        systemctl enable httpd
        chmod -R 755 /var/www

        echo "DB_SERVER=${aws_db_instance.this.address}" >> /etc/environment
        echo "DB_USERNAME=admin" >> /etc/environment
        echo "DB_PASSWORD=1Password1" >> /etc/environment
        echo "DB_DATABASE=sample" >> /etc/environment

        INSTANCE_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
        AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
        PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
        echo "INSTANCE_NAME=$INSTANCE_NAME" >> /etc/environment
        echo "AZ=$AZ" >> /etc/environment
        echo "PRIVATE_IP=$PRIVATE_IP" >> /etc/environment
        
        source /etc/environment
        
        git clone https://github.com/rearviewmirror/platform_academy.git /tmp/platform_academy
        cp /tmp/platform_academy/db_connect.inc /var/www/html/db_connect.inc
        cp /tmp/platform_academy/index.php /var/www/html/index.php
    EOF

  tags = {
    Name = "Webserver-${count.index}"
  }

  security_groups = [aws_security_group.web-sg.id]
  depends_on      = [aws_db_instance.this]
}
