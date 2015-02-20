name 'wemux'
description 'wemux pair'

run_list(
  'role[base]',
  'recipe[wemux]',
  'recipe[wemux::users]'
)
