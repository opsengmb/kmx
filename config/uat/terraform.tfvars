region  = "ap-southeast-1"
project = "kumaxx"
env_name = "uat"

// network details
vpc_cidr = "10.52.0.0/16"
pub_a = "10.52.0.0/24"
priv_a = "10.52.1.0/24"
priv_b = "10.52.2.0/24"
priv_c = "10.52.3.0/24"
az_a = "ap-southeast-1a"
az_b = "ap-southeast-1b"

// domains
gl_fe_domain = "kumaxx-uat.ph"
gl_be_domain = "gl-be.kumaxxkumaxx-uat.ph"
bo_fe_domain = "bo-fe.XXXXXXXX"
bo_be_domain = "bo-be.XXXXXXXX"
jobproc_domain = "jobproc.XXXXXXXX"
cert_id = "137843-ap-southeast-1"

// image id
image_id = "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
gl_fe_image_id = "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
gl_be_image_id =  "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
bo_fe_image_id =  "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
bo_be_image_id =  "ubuntu_24_04_x64_20G_alibase_20240923.vhd"
jp_image_id =  "ubuntu_24_04_x64_20G_alibase_20240923.vhd"

// db instance type
db_instance_type = "mariadb.x4.large.2c"
db_instance_storage = "100"
db_category = "Basic"
db_engine_version = "10.3"

// bridge data
bridge_image_id = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
bridge_vpc_cidr = "10.62.0.0/27"
bridge_pub_a = "10.62.0.0/28"
bridge_az_a = "ap-northeast-1a"