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

## Step 6: EC2 and IAM

**Built:** a key pair, an IAM role with an instance profile, and two EC2 nodes (`ec2.tf`, `iam.tf`).

**Nodes**
| Node | Role | Disk |
|---|---|---|
| barq-control-plane | Kubernetes control plane | 20 GB |
| barq-worker | Runs NGINX, Flask, Redis | 30 GB |

**Decisions**
- **`t3.medium`:** kubeadm requires at least 2 vCPU and 2 GB RAM.
- **AMI found by a `data` lookup (Ubuntu 24.04):** nothing is hardcoded, so it works in any region. `ignore_changes = [ami]` stops a newer image from replacing working nodes.
- **`for_each` over a map:** one block builds both nodes, with differences visible in one place.
- **IMDSv2 required:** blocks credential theft through the metadata service.
- **Encrypted gp3 root volumes:** no extra cost, standard practice.
- **IAM role has only the SSM policy:** least privilege, and Session Manager is break-glass access if SSH is blocked.
- **Only the public key goes to Terraform:** the private key never enters Git or state.

**Operational notes**
- The SSH CIDR list must include every teammate's IP, and the private key is shared through a secure channel, never Git.
- A validation rejects an empty SSH list.

**Verification:** `terraform plan` shows 27 resources to add in total.

## Step 7: RDS PostgreSQL

**Built:** one PostgreSQL instance in the private DB subnets (`rds.tf`).

**Settings**
| Setting | Value |
|---|---|
| Engine | PostgreSQL 16 |
| Class | m7i-flex.large |
| Storage | 20 GB gp3, encrypted |
| Access | Not public, nodes SG only |
| Multi-AZ | Off (lab) |

**Decisions**
- **Three access layers:** private subnets, `publicly_accessible = false`, and an SG that allows port 5432 only from the nodes SG.
- **Password from `TF_VAR_db_password`:** a `sensitive` variable with no default, so it is never committed.
- **Major version only:** AWS picks a current minor version, so nothing retired is hardcoded.
- **Lab shortcuts:** `skip_final_snapshot = true` and `deletion_protection = false` so `terraform destroy` works. Production should reverse both.

**Known limitation:** the password is stored in plain text in `terraform.tfstate`, so state stays out of Git. A production setup would use `manage_master_user_password` or a remote encrypted backend.

**Verification:** `terraform plan` shows 28 resources to add in total.