
# Flask CDK Deploy Script
# Automates AWS CDK setup, environment creation, and deployment
# ------------------------------------------------------------

set -euo pipefail

# === CONFIGURATION ===
PROJECT_NAME="flask-cdk"
AWS_REGION="${AWS_REGION:-eu-north-1}"
PYTHON_VERSION="${PYTHON_VERSION:-python3}"

echo "Starting Flask CDK Deployment Script..."
echo "========================================="

# === Step 1: Install AWS CDK ===
echo "Installing AWS CDK "
npm install -g aws-cdk
echo "AWS CDK version: $(cdk --version)"

# === Step 2: Create project folder if not exists ===
if [ ! -d "$PROJECT_NAME" ]; then
  echo "Creating new CDK project folder: $PROJECT_NAME"
  mkdir "$PROJECT_NAME"
  cd "$PROJECT_NAME"
  cdk init app --language python
else
  echo "Project folder already exists. Using existing folder."
  cd "$PROJECT_NAME"
fi

# === Step 3: Set up Python environment ===
echo "Setting up Python virtual environment..."
$PYTHON_VERSION -m venv .env
source .env/bin/activate
pip install --upgrade pip

# === Step 4: Install dependencies ===
echo "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt || true
fi
pip install "aws-cdk-lib>=2.0.0" "constructs>=10.0.0,<11.0.0"

# === Step 5: Replace the stack file contents ===
STACK_FILE="flask_cdk/flask_cdk_stack.py"
echo "Writing Flask CDK stack definition to $STACK_FILE"

mkdir -p flask_cdk
cat > "$STACK_FILE" << 'EOF'
from aws_cdk import ( 
    Stack,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns,
    aws_iam as iam,
    CfnOutput,
)
from constructs import Construct


class FlaskCdkStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Create a new VPC
        vpc = ec2.Vpc(self, "FlaskVpc", max_azs=2)

        # Create ECS Cluster
        cluster = ecs.Cluster(self, "FlaskCluster", vpc=vpc)

        # Create ECS Task Execution Role with proper permissions
        execution_role = iam.Role(
            self, "FlaskTaskExecutionRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com")
        )
        execution_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name(
                "service-role/AmazonECSTaskExecutionRolePolicy"
            )
        )

        # Create Fargate service behind a Load Balancer
        flask_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self,
            "FlaskService",
            cluster=cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            public_load_balancer=True,
            task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
                image=ecs.ContainerImage.from_registry(
                    "593970662859.dkr.ecr.eu-north-1.amazonaws.com/mathapp-repo:latest"
                ),
                container_port=5000,
                execution_role=execution_role  # <-- assign role here
            ),
        )

        # Output Load Balancer DNS
        CfnOutput(self, "LoadBalancerURL",
            value=f"http://{flask_service.load_balancer.load_balancer_dns_name}"
        )
EOF

# === Step 6: Bootstrap and deploy the stack ===
echo "Bootstrapping AWS environment..."
cdk bootstrap 

echo "Deploying CDK stack..."
cdk deploy 

echo "Deployment completed successfully!"
echo "Check CloudFormation outputs for LoadBalancerURL."

