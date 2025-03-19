
#https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

    name = "${var.cluster_name}-vpc"
    cidr = "10.0.0.0/16"

    azs              = ["${var.region}a", "${var.region}b", "${var.region}c"]
    public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    intra_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false

    # https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html#_prerequisites
    public_subnet_tags = {
        "kubernetes.io/role/elb" = 1
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = 1
        # https://karpenter.sh/docs/concepts/nodeclasses/#specsubnetselectorterms
        "karpenter.sh/discovery" = var.cluster_name
    }
}