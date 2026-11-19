environment        = "dev"
region             = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
single_nat_gateway = true

node_capacity_type = "SPOT"
node_min_size      = 2
node_desired_size  = 2
node_max_size      = 4
