data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_instance" "node" {
    count = var.instance_count
    ami = data.aws_ami.amazon_linux.subnet_id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    iam_instance_profile = var.instance_profile
    key_name = var.key_name != "" ? var.key_name : null

    root_block_device {
        volume_size = 20
        voulme_type = "gp3"
    }

    user_data = templatefile("${path.module}/bootstrap.sh", {
        node_type = var.node_type
    })

    tags = {
        Name = "${var.cluster_name}-${var.environment}-${var.node_type}-${count.index + 1}"
    Environment = var.environment
    }
}
