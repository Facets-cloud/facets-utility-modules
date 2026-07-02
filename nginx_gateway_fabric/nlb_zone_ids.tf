# AWS-published Network Load Balancer canonical hosted zone IDs, per region. Used to build the
# base-domain Route53 alias A record without an ELB API call: the LB is provisioned async in the
# cloud account (unreachable from the release pod), and the id is a per-region AWS constant.
# https://docs.aws.amazon.com/general/latest/gr/elb.html
locals {
  nlb_hosted_zone_ids = {
    "us-east-1"      = "Z26RNL4JYFTOTI"
    "us-east-2"      = "ZLMOA37VPKANP"
    "us-west-1"      = "Z24FKFUX50B4VW"
    "us-west-2"      = "Z18D5FSROUN65G"
    "af-south-1"     = "Z203XCE67M25HM"
    "ap-east-1"      = "Z12Y7K3UBGUAD1"
    "ap-south-1"     = "ZVDDRBQ08TROA"
    "ap-south-2"     = "Z0711778386UTO08407HT"
    "ap-northeast-1" = "Z31USIVHYNEOWT"
    "ap-northeast-2" = "ZIBE1TIR4HY56"
    "ap-northeast-3" = "Z1GWIQ4HH19I5X"
    "ap-southeast-1" = "ZKVM4W9LS7TM"
    "ap-southeast-2" = "ZCT6FZBF4DROD"
    "ap-southeast-3" = "Z01971771FYVNCOVWJU1G"
    "ap-southeast-4" = "Z01156963G8MIIL7X90IV"
    "ca-central-1"   = "Z2EPGBW3API2WT"
    "ca-west-1"      = "Z069246665OJI6OO3M8V4"
    "eu-central-1"   = "Z3F0SRJ5LGBH90"
    "eu-central-2"   = "Z02239872DOALSIDCX66S"
    "eu-west-1"      = "Z2IFOLAFXWLO4F"
    "eu-west-2"      = "ZD4D7Y8KGAS4G"
    "eu-west-3"      = "Z1CMS0P5QUZ6D5"
    "eu-south-1"     = "Z23146JA1KNAFP"
    "eu-south-2"     = "Z1011216NVTVYADP1SSV"
    "eu-north-1"     = "Z1UDT6IFJ4EJM"
    "me-south-1"     = "Z3QSRYVP46NYYV"
    "me-central-1"   = "Z00282643NTTLPANJJG2P"
    "il-central-1"   = "Z0313266YDI6ZRHTGQY4"
    "sa-east-1"      = "ZTK26PT1VY4CU"
    "us-gov-west-1"  = "ZMG1MZ2THAWF1"
    "us-gov-east-1"  = "Z1ZSMQQ6Q24QQ8"
  }
}
