locals {
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidrs = [
        "10.0.10.0/24",
        "10.0.20.0/24"
    ]
    private_subnet_cidrs = [
        "10.0.30.0/24",
        "10.0.40.0/24"
    ]
    availability_zones = ["eu-west-2a", "eu-west-2b"]
    region             = "eu-west-2"


    eks_version = "1.33"

    route53_zone_arn = "arn:aws:route53:::hostedzone/Z02290411JA35JCBMQUUJ"
    
}