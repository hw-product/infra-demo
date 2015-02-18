name 'gemstore'

run_list(
  'role[base]',
  'recipe[geminabox]'
)

default_attributes(
  :geminabox => {
    :ssl => {
      :enabled => true,
      :snakeoil => true
    },
    :auth_required => {
      :demo => '8sYl7Bo0ql2OA9OPThUngg'
    },
    :unicorn => {
      :exec => '/opt/chef/embedded/bin/unicorn'
    }
  }
)
