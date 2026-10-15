## Step 3: Network

**Built:** VPC, public subnet, internet gateway, route table, route table association (`network.tf`).

**CIDR plan**
| Resource | CIDR |
|---|---|
| VPC | 10.0.0.0/16 |
| Public subnet | 10.0.1.0/24 |

DB subnets will use separate ranges inside the VPC, with no overlap.

**Decisions**
- **/16 VPC, /24 subnets:** a large address pool, split into small slices, leaves room to add subnets.
- **DNS support and hostnames enabled:** nodes get resolvable names.
- **AZ chosen with a `data` lookup:** nothing is hardcoded, so it works in any region.
- **Public subnet = route to IGW:** the `0.0.0.0/0` route through the internet gateway, associated with the subnet, is what makes it public.
- **`map_public_ip_on_launch`:** EC2 nodes get public IPs for SSH and NodePort access.

**Verification:** `terraform plan` shows 5 resources to add.

## Step 4: DB subnets

**Built:** two private DB subnets in different AZs, a private route table, and a DB subnet group (`network.tf`).

**CIDR plan**
| Resource | CIDR |
|---|---|
| DB subnet 1 | 10.0.11.0/24 |
| DB subnet 2 | 10.0.12.0/24 |

**Decisions**
- **Two AZs:** an RDS subnet group requires at least two, and Multi-AZ stays possible later.
- **Private route table, no internet route:** blocks the internet. Security groups control access from inside the VPC.
- **No NAT gateway:** RDS needs no outbound internet, and NAT adds cost.
- **`count` with a list variable:** one block builds both subnets, each in a different AZ.

**Verification:** `terraform plan` shows 11 resources to add in total.