SparkleFormation.new("yetty").load(:base, :chef).overrides do

  # Yetty app resources
  dynamic!(:asg, 'yetty',
    :run_list => [
      'role[yetty]'
    ],
    :load_balancers => [
      ref!(:yetty_load_balancer)
    ]
  )

  [80, 443].each do |port|
    dynamic!(:ec2_security_group_ingress, "elb_#{port}") do
      properties do
        source_security_group_name attr!(:yetty_load_balancer, 'SourceSecurityGroup.GroupName')
        source_security_group_owner_id attr!(:yetty_load_balancer, 'SourceSecurityGroup.OwnerAlias')
        from_port port
        to_port port
        group_name ref!(:yetty_security_group)
        ip_protocol 'tcp'
      end
    end
  end

  dynamic!(:load_balancer, 'yetty')

  # Asset store setup and access resources
  dynamic!(:bucket, :yetty)

  dynamic!(:iam_user, :yetty) do
    properties do
      path '/'
      policies array!(
        -> {
          policy_name 'yetty_bucket_access'
          policy_document.statement array!(
            -> {
              effect 'Allow'
              action [
                's3:ListAllMyBuckets',
                's3:ListMultipartUploadParts',
                's3:DeleteObject',
                's3:ListBucket',
                's3:GetObject',
                's3:ListBucketMultipartUploads',
                's3:PutObject',
                's3:AbortMultipartUpload',
                's3:GetBucketLocation'
              ]
            }
          )
        }
      )
    end
  end

  dynamic!(:iam_access_key, :yetty) do
    properties.user_name ref!(:yetty_iam_user)
  end

  resources.yetty_launch_configuration.metadata('AWS::CloudFormation::Init') do
    config.files('/etc/chef/first_run.json') do
      content.yetty.config.site.storage do
        bucket ref!(:yetty_bucket)
        credentials do
          aws_access_key_id ref!(:yetty_iam_access_key)
          aws_secret_access_key attr!(:yetty_iam_access_key, :secret_access_key)
          aws_bucket_region region!
        end
      end
    end
  end

  parameters do
    yetty_load_balancer_port.default '80'
    yetty_instance_port.default '80'
    yetty_load_balancer_protocol.default 'HTTP'
    yetty_instance_protocol.default 'HTTP'
    yetty_load_balancer_hc_check_path.default '/'
  end

  outputs do
    yetty_site do
      description 'Yetty site location'
      value join!('http://', attr!(:yetty_load_balancer, 'DNSName'))
    end
    yetty_bucket do
      description 'Yetty Bucket'
      value ref!(:yetty_bucket)
    end
    yetty_bucket_region do
      description 'Region of Yetty Bucket'
      value region!
    end
    yetty_access_key do
      description 'Yetty access key'
      value ref!(:yetty_iam_access_key)
    end
    yetty_secret_key do
      description 'Yetty secret key'
      value attr!(:yetty_iam_access_key, :secret_access_key)
    end
  end

end
