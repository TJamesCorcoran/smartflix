# ============================================================================= #
# a rake file for building tags.                                                #
# ============================================================================= #
namespace :tags do
  desc "generate tags table for all .rb files found beneath"
  task(:generate) do

    `rtags -R .`

  end
end
