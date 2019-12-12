require "test_helper"

describe "Synthesis Benchmark" do
  it "branching" do

    class SiteSettings
      class << self
        reserved_usernames = []
        attr_accessor :reserved_usernames
      end

      def self.reserved_username?(username)
        SiteSettings.reserved_usernames.include? username
      end
    end
    RDL.type SiteSettings, 'self.reserved_username?', '(String) -> %bool', wrap: false

    define :username_available?, "(String) -> %bool", components: [SiteSettings] do

      reset {
        SiteSettings.reserved_usernames = []
      }

      spec "returns true when user doesn't exist" do
        username_available? 'bruce1'

        post { |result|
          result == true
        }
      end

      spec "returns false when user exists" do
        pre {
          u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
          u.emails.create(email: 'bruce1@wayne.com')
        }

        username_available? 'bruce1'

        post { |result|
          result == false
        }
      end

      spec "returns false when username is reserved" do
        pre {
          SiteSettings.reserved_usernames = ['apple', 'dog']
        }

        username_available? 'apple'

        post { |result|
          result == false
        }
      end

      assert_equal generate_program, %{
def username_available?(arg0)
  if SiteSettings.reserved_username?(arg0)
    false
  else
    !User.exists?(username: arg0)
  end
end
}.strip

    end
  end
end