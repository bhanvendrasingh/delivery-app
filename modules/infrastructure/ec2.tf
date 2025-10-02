# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "image-id"
    values = ["ami-0bd4cda58efa33d23"] # Ubuntu 24.04 LTS x86_64 in ap-south-2
  }
}

# # Key pair for EC2 instances
# resource "aws_key_pair" "kafka" {
#   key_name   = "${local.name_prefix}-kafka-key"
#   public_key = var.kafka_public_key

#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-kafka-key"
#   })
# }

# Kafka EC2 Instance
resource "aws_instance" "kafka" {
  count                  = var.kafka.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.kafka.instance_type
  key_name               = var.kafka.key_name
  vpc_security_group_ids = [aws_security_group.kafka.id]
  subnet_id              = module.vpc.private_subnets[0]
  
  # Enable detailed monitoring
  monitoring = var.environment == "prod"
  
  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.kafka.volume_size
    delete_on_termination = true
    encrypted             = true
    
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-kafka-${count.index}-root"
    })
  }
}
