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

## Step 5: Security groups

**Built:** a nodes security group and an RDS security group, with a separate rule resource for each rule (`security.tf`).

**Nodes SG: inbound rules**
| Source | Port | Purpose |
|---|---|---|
| `allowed_ssh_cidrs` | TCP 22 | Admin and Ansible SSH |
| Nodes SG (self) | TCP 6443 | Kubernetes API server |
| Nodes SG (self) | TCP 2379-2380 | etcd |
| Nodes SG (self) | TCP 10250 | kubelet |
| Nodes SG (self) | UDP 8472 | CNI overlay (Flannel VXLAN) |
| `app_access_cidrs` | TCP 30080 | NGINX NodePort, the only public port |

**RDS SG: inbound rules**
| Source | Port | Purpose |
|---|---|---|
| Nodes SG | TCP 5432 | PostgreSQL from nodes only |

**Decisions**
- **Separate rule resources:** inline rules conflict and are harder to review.
- **SSH has no default and rejects `0.0.0.0/0`:** a validation forces an explicit, restricted IP list.
- **Self-referencing rules:** Kubernetes ports are reachable only from the nodes themselves.
- **Only port 30080 is public:** not the whole NodePort range.
- **Explicit egress on nodes:** needed for package installs and image pulls.
- **No egress on the RDS SG:** security groups are stateful, and the database never initiates connections.

**Known limitation:** the SG allows RDS access from the whole node group, so any pod on a node can reach the database. A NetworkPolicy would restrict this to Flask.

**Operational notes**
- Real IPs go in `terraform.tfvars` (gitignored), with a safe `terraform.tfvars.example` committed.
- Whoever runs `apply` must include every teammate's IP, especially the Ansible owner's.
- The CNI rule must match the plugin Ansible installs.