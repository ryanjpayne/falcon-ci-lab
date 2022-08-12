
data "aws_caller_identity" "current" {}
data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
data "aws_ami" "amazon" {
 most_recent = true
 owners = ["amazon"]
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_iam_role_policy" "crowdstrike_bootstrap_policy" {
  name = "crowdstrike_bootstrap_policy"
  role = aws_iam_role.crowdstrike_bootstrap_role.id
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
resource "aws_iam_role" "crowdstrike_bootstrap_role" {
  name = "crowdstrike_bootstrap_role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/BoundaryForAdministratorAccess"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "crowdstrike_bootstrap_policy_attach" {
  role       = "${aws_iam_role.crowdstrike_bootstrap_role.name}"
  policy_arn = "${data.aws_iam_policy.AdministratorAccess.arn}"
}
resource "aws_iam_instance_profile" "crowdstrike_bootstrap_profile" {
  name = "crowdstrike_bootstrap_profile"
  role = aws_iam_role.crowdstrike_bootstrap_role.name
}
resource "aws_instance" "aws-linux-server" {
  count         = "1"
  ami           = data.aws_ami.amazon.id
  instance_type = "t2.small"
  key_name      = "cs-key"
  iam_instance_profile = aws_iam_instance_profile.crowdstrike_bootstrap_profile.id
  associate_public_ip_address = true
  tags = {
    Name = "Startup"
    ci-key-username = "ec2-user"
  }
  user_data = <<EOF
#!/bin/bash
echo "${var.CS_Env_Id}" > /tmp/environment.txt;
echo "export CS_Env_Id=${var.CS_Env_Id}" >> /etc/profile
echo "export EXT_IP=$(curl -s ipinfo.io/ip)"
echo 'echo -e "Welcome to the demo!\n\nUse the command \`start\` to begin."' >> /etc/profile
az=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
region="`echo \"$az\" | sed 's/[a-z]$//'`"
aws configure region $region
yum -y install unzip
yum -y install git
cd /home/ec2-user
git clone https://github.com/ryanjpayne/falcon-ci-lab.git
mv falcon-ci-lab/scripts/start.sh /usr/local/bin/start
chmod +x /usr/local/bin/start
chmod +x /home/ec2-user/flacon-ci-lab/scripts/deploy.sh
EOF
}