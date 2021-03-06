# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1304
# test ordering matters in this to get a successful synthesis
require "test_helper"

describe "Discourse" do
  it "clear_global_notice_if_needed" do
    load_typedefs :stdlib, :active_record

    class DiscourseSiteSetting
      class << self
        attr_accessor :has_login_hint, :global_notice
      end
    end

    RDL.type DiscourseSiteSetting, 'self.has_login_hint', '() -> %bool', read: ['DiscourseSiteSetting.has_login_hint'], wrap: false
    RDL.type DiscourseSiteSetting, 'self.has_login_hint=', '(%bool) -> %bool', write: ['DiscourseSiteSetting.has_login_hint'], wrap: false
    RDL.type DiscourseSiteSetting, 'self.global_notice', '() -> String', read: ['DiscourseSiteSetting.global_notice'], wrap: false
    RDL.type DiscourseSiteSetting, 'self.global_notice=', '(String) -> String', write: ['DiscourseSiteSetting.global_notice'], wrap: false

    RDL.type Integer, :<, '(Integer) -> %bool', wrap: false

    define :clear_global_notice_if_needed, "(User) -> %bot", [DiscourseSiteSetting], prog_size: 30, consts: true do

      spec "doesn't clear the notice when a system user is saved" do
        setup {
          system_user = Fabricate(:admin, id: -1)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(system_user)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == true }
          assert { DiscourseSiteSetting.global_notice == "some notice" }
        }
      end

      spec "clears the notice when the admin is saved" do
        setup {
          admin = Fabricate(:admin)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(admin)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == false }
          assert { DiscourseSiteSetting.global_notice == "" }
        }
      end

      spec "doesn't clear the login hint when a regular user is saved" do
        setup {
          user = Fabricate(:user, admin: false)
          DiscourseSiteSetting.has_login_hint = true
          DiscourseSiteSetting.global_notice = "some notice"
          clear_global_notice_if_needed(user)
        }

        post { |result|
          assert { DiscourseSiteSetting.has_login_hint == true }
          assert { DiscourseSiteSetting.global_notice == "some notice" }
        }
      end

      generate_program
    end
  end
end
