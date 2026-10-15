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