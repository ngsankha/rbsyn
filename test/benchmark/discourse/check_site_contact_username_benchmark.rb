# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1532
require "test_helper"

describe "Discourse" do
  it "check_site_contact_username" do
    load_typedefs :stdlib, :active_record

    class DiscourseSiteSetting
      def self.set_and_log(field, value)
        case field
        when :site_contact_username
          @@site_contact_username = value
        else
          raise RuntimeError, "unknown field"
        end
      end

      def self.site_contact_username
        @@site_contact_username
      end

      def self.site_contact_username=(username)
        @@site_contact_username = username
      end

      def self.defaults
        { site_contact_username: 'default_contact' }
      end
    end

    RDL.type DiscourseSiteSetting, 'self.set_and_log', '(:site_contact_username, String) -> %bot', write: ['DiscourseSiteSetting'], wrap: false
    RDL.type DiscourseSiteSetting, 'self.site_contact_username', '() -> String', read: ['DiscourseSiteSetting.site_contact_username'], wrap: false
    RDL.type DiscourseSiteSetting, 'self.defaults', '() -> { site_contact_username: String }', read: ['DiscourseSiteSetting'], wrap: false
    RDL.type User, :staff?, '() -> %bool', read: ['User'], wrap: false

    define :check_site_contact_username, "(User) -> %bot", [DiscourseSiteSetting] do

      spec "clears site_contact_username site setting when admin privilege is revoked" do
        pre {
          @contact_user = Fabricate(:admin)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      spec "clears site_contact_username site setting when moderator privilege is revoked" do
        pre {
          @contact_user = Fabricate(:moderator)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      spec "does not change site_contact_username site setting when admin privilege is revoked" do
        pre {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == @contact_user.username }
        }
      end

      spec "does not change site_contact_username site setting when moderator privilege is revoked" do
        pre {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == @contact_user.username }
        }
      end

      spec "clears site_contact_username site setting when staff privileges are revoked" do
        pre {
          @contact_user = Fabricate(:moderator, admin: true)
          DiscourseSiteSetting.site_contact_username = @contact_user.username
          @contact_user.revoke_admin!
          @contact_user.revoke_moderation!
          check_site_contact_username(@contact_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.site_contact_username == DiscourseSiteSetting.defaults[:site_contact_username] }
        }
      end

      generate_program
    end
  end
end
